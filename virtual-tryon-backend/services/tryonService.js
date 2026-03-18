// =============================================
// IDM-VTON SERVICE - FIXED VERSION
// Handles sleeping HF spaces + retry logic
// =============================================

const { Client } = require("@gradio/client");
const { Blob } = require('buffer');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const HF_API_KEY = process.env.HUGGINGFACE_API_KEY;
const SPACE_ID = "yisol/IDM-VTON";
const SPACE_URL = "https://yisol-idm-vton.hf.space";

// ─── Wake the sleeping space ──────────────────────────────────────────────────
const wakeSpace = async () => {
    console.log('   Waking IDM-VTON space...');

    // Ping the space root to trigger wake-up
    try {
        await axios.get(SPACE_URL, {
            headers: HF_API_KEY ? { 'Authorization': `Bearer ${HF_API_KEY}` } : {},
            timeout: 30000,
            validateStatus: () => true
        });
    } catch (e) {
        console.log('   Wake ping error (non-fatal):', e.message);
    }

    // Try restart endpoint
    try {
        await axios.post(
            `https://huggingface.co/api/spaces/${SPACE_ID}/restart`,
            {},
            {
                headers: HF_API_KEY ? { 'Authorization': `Bearer ${HF_API_KEY}` } : {},
                timeout: 10000,
                validateStatus: () => true
            }
        );
    } catch (e) { /* ignore */ }

    // Poll until RUNNING
    for (let attempt = 1; attempt <= 12; attempt++) {
        try {
            const res = await axios.get(
                `https://huggingface.co/api/spaces/${SPACE_ID}`,
                {
                    headers: HF_API_KEY ? { 'Authorization': `Bearer ${HF_API_KEY}` } : {},
                    timeout: 15000
                }
            );
            const stage = res.data?.runtime?.stage;
            console.log(`   [${attempt}/12] Space stage: ${stage}`);
            if (stage === 'RUNNING' || stage === 'RUNNING_BUILDING') {
                console.log('   Space is running!');
                return true;
            }
        } catch (e) {
            console.log(`   Poll ${attempt} failed:`, e.message);
        }
        if (attempt < 12) {
            console.log('   Waiting 10s...');
            await new Promise(r => setTimeout(r, 10000));
        }
    }
    console.log('   Space may not be fully awake, attempting anyway...');
    return false;
};

// ─── Connect with retry ───────────────────────────────────────────────────────
const connectWithRetry = async (maxRetries = 3) => {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            console.log(`   Connecting to Gradio client (attempt ${attempt}/${maxRetries})...`);
            const client = await Client.connect(SPACE_ID, {
                hf_token: HF_API_KEY
            });
            console.log('   Connected!');
            return client;
        } catch (error) {
            console.log(`   Connect attempt ${attempt} failed: ${error.message}`);
            if (error.message.includes('Space metadata could not be loaded')) {
                if (attempt < maxRetries) {
                    const wait = attempt * 20000;
                    console.log(`   Waiting ${wait / 1000}s then retrying...`);
                    await new Promise(r => setTimeout(r, wait));
                    await wakeSpace();
                }
            } else {
                throw error;
            }
        }
    }
    throw new Error('Could not connect to IDM-VTON after ' + maxRetries + ' attempts');
};

// ─── Download image from result ───────────────────────────────────────────────
const extractImage = async (resultData) => {
    if (!resultData) throw new Error('Result data is null');

    if (typeof resultData === 'string') {
        if (resultData.startsWith('data:image')) {
            return Buffer.from(resultData.split(',')[1], 'base64');
        }
        const url = resultData.startsWith('http')
            ? resultData
            : `${SPACE_URL}/file=${resultData}`;
        const r = await axios.get(url, { responseType: 'arraybuffer', timeout: 60000 });
        return Buffer.from(r.data);
    }

    if (resultData.url || resultData.path || resultData.name) {
        const url = resultData.url
            || `${SPACE_URL}/file=${resultData.path || resultData.name}`;
        const r = await axios.get(url, { responseType: 'arraybuffer', timeout: 60000 });
        return Buffer.from(r.data);
    }

    throw new Error('Unknown result format: ' + JSON.stringify(resultData).substring(0, 200));
};

// ─── Single try-on ────────────────────────────────────────────────────────────
const processSingleTryOn = async (userImagePath, dressImagePath) => {
    if (!fs.existsSync(userImagePath)) throw new Error(`User image not found: ${userImagePath}`);
    if (!fs.existsSync(dressImagePath)) throw new Error(`Dress image not found: ${dressImagePath}`);

    console.log('Processing IDM-VTON try-on...');

    await wakeSpace();
    const client = await connectWithRetry(3);

    const userBlob = new Blob([fs.readFileSync(userImagePath)], { type: 'image/jpeg' });
    const dressBlob = new Blob([fs.readFileSync(dressImagePath)], { type: 'image/jpeg' });

    console.log('   Sending to AI model...');

    const result = await client.predict("/tryon", {
        dict: { background: userBlob, layers: [], composite: null },
        garm_img: dressBlob,
        garment_des: "a beautiful dress",
        is_checked: true,
        is_checked_crop: false,
        denoise_steps: 30,
        seed: 42
    });

    if (!result?.data) throw new Error('No result data from Space');

    const imageBuffer = await extractImage(result.data[0]);
    console.log('   Try-on complete! Size:', (imageBuffer.length / 1024).toFixed(2), 'KB');
    return imageBuffer;
};

// ─── Multiple try-ons ─────────────────────────────────────────────────────────
const processMultipleTryOns = async (userImagePath, dressImagePaths) => {
    const results = [];

    console.log(`\nProcessing ${dressImagePaths.length} IDM-VTON try-ons...`);
    console.log('Waking space first — may take 2-3 minutes if sleeping\n');

    // Wake once before the loop
    await wakeSpace();
    let client = null;

    for (let i = 0; i < dressImagePaths.length; i++) {
        try {
            console.log(`[${i + 1}/${dressImagePaths.length}] Processing dress...`);

            if (client === null) {
                client = await connectWithRetry(3);
            }

            const userBlob = new Blob([fs.readFileSync(userImagePath)], { type: 'image/jpeg' });
            const dressBlob = new Blob([fs.readFileSync(dressImagePaths[i])], { type: 'image/jpeg' });

            const result = await client.predict("/tryon", {
                dict: { background: userBlob, layers: [], composite: null },
                garm_img: dressBlob,
                garment_des: "a beautiful dress",
                is_checked: true,
                is_checked_crop: false,
                denoise_steps: 30,
                seed: 42
            });

            if (!result?.data) throw new Error('No result data from Space');

            const imageBuffer = await extractImage(result.data[0]);

            const outputDir = './uploads/tryon-results';
            if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

            const filename = `tryon-${Date.now()}-${i}.jpg`;
            fs.writeFileSync(path.join(outputDir, filename), imageBuffer);

            results.push({
                success: true,
                dressIndex: i,
                resultUrl: `/uploads/tryon-results/${filename}`,
                dressImagePath: dressImagePaths[i],
                aiGenerated: true,
                method: 'IDM-VTON AI'
            });

            console.log(`   Dress ${i + 1} done!\n`);

        } catch (error) {
            console.error(`   Failed dress ${i + 1}:`, error.message, '\n');
            if (error.message.includes('metadata') || error.message.includes('connect')) {
                client = null; // reset so next dress reconnects
            }
            results.push({
                success: false,
                dressIndex: i,
                error: error.message,
                dressImagePath: dressImagePaths[i],
                aiGenerated: false
            });
        }

        if (i < dressImagePaths.length - 1) {
            await new Promise(r => setTimeout(r, 5000));
        }
    }

    return results;
};

const simpleTryOnFallback = async (userImagePath, dressImagePath) => {
    const outputDir = './uploads/tryon-results';
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });
    const filename = `tryon-fallback-${Date.now()}.jpg`;
    fs.writeFileSync(path.join(outputDir, filename), fs.readFileSync(dressImagePath));
    return { success: true, resultUrl: `/uploads/tryon-results/${filename}`, aiGenerated: false };
};

const checkAPIAvailability = async () => {
    if (!HF_API_KEY || HF_API_KEY.length < 10) return false;
    try {
        const res = await axios.get(
            `https://huggingface.co/api/spaces/${SPACE_ID}`,
            { headers: { 'Authorization': `Bearer ${HF_API_KEY}` }, timeout: 10000 }
        );
        const stage = res.data?.runtime?.stage;
        console.log(`Space stage: ${stage}`);
        return stage === 'RUNNING' || stage === 'SLEEPING';
    } catch (e) {
        return false;
    }
};

module.exports = {
    processSingleTryOn,
    processMultipleTryOns,
    simpleTryOnFallback,
    checkAPIAvailability
};