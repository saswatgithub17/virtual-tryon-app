// =============================================
// IDM-VTON SERVICE - FINAL WORKING VERSION
// Proper file handling with Blob format
// =============================================

const { Client } = require("@gradio/client");
const { Blob } = require('buffer');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const HF_API_KEY = process.env.HUGGINGFACE_API_KEY;
const SPACE_URL = "yisol/IDM-VTON";

/**
 * Process Virtual Try-On using IDM-VTON Space
 */
const processSingleTryOn = async (userImagePath, dressImagePath) => {
    try {
        console.log('🎨 Processing IDM-VTON try-on...');
        console.log('   User image:', userImagePath);
        console.log('   Dress image:', dressImagePath);

        // Validate files exist
        if (!fs.existsSync(userImagePath)) {
            throw new Error(`User image not found: ${userImagePath}`);
        }
        if (!fs.existsSync(dressImagePath)) {
            throw new Error(`Dress image not found: ${dressImagePath}`);
        }

        console.log('   Connecting to IDM-VTON Space...');
        
        const client = await Client.connect(SPACE_URL, {
            hf_token: HF_API_KEY
        });

        console.log('   ✅ Connected!');
        console.log('   Preparing image files...');

        // Read files as buffers
        const userBuffer = fs.readFileSync(userImagePath);
        const dressBuffer = fs.readFileSync(dressImagePath);

        // Create Blob objects (this is what Gradio expects)
        const userBlob = new Blob([userBuffer], { type: 'image/jpeg' });
        const dressBlob = new Blob([dressBuffer], { type: 'image/jpeg' });

        console.log('   User image size:', (userBuffer.length / 1024).toFixed(2), 'KB');
        console.log('   Dress image size:', (dressBuffer.length / 1024).toFixed(2), 'KB');
        console.log('   Sending to AI model... (this may take 2-3 minutes)');

        // Call the Space with proper format
        const result = await client.predict("/tryon", {
            dict: {
                background: userBlob,  // Send as Blob
                layers: [],
                composite: null
            },
            garm_img: dressBlob,      // Send as Blob
            garment_des: "a beautiful dress",
            is_checked: true,
            is_checked_crop: false,
            denoise_steps: 30,
            seed: 42
        });

        console.log('   ✅ AI processing complete!');
        console.log('   Extracting result...');

        // Extract image from result
        if (!result || !result.data) {
            throw new Error('No result data from Space');
        }

        console.log('   Result data type:', typeof result.data);
        console.log('   Result data length:', Array.isArray(result.data) ? result.data.length : 'not array');

        // The result should contain the processed image
        let imageBuffer;
        const resultData = result.data[0]; // First output is the result image

        console.log('   Result item type:', typeof resultData);
        console.log('   Result item keys:', resultData ? Object.keys(resultData) : 'null');

        // Handle different result formats
        if (typeof resultData === 'string') {
            // It's a URL
            if (resultData.startsWith('http')) {
                console.log('   Downloading from URL...');
                const response = await axios.get(resultData, {
                    responseType: 'arraybuffer',
                    timeout: 30000
                });
                imageBuffer = Buffer.from(response.data);
            } else if (resultData.startsWith('/')) {
                // File path on Space
                const fileUrl = `https://yisol-idm-vton.hf.space/file=${resultData}`;
                console.log('   Downloading from Space file:', fileUrl);
                const response = await axios.get(fileUrl, {
                    responseType: 'arraybuffer',
                    timeout: 30000
                });
                imageBuffer = Buffer.from(response.data);
            } else {
                throw new Error('Unexpected string format: ' + resultData.substring(0, 100));
            }
        } else if (resultData && resultData.url) {
            // Has url property
            console.log('   Downloading from result.url...');
            const response = await axios.get(resultData.url, {
                responseType: 'arraybuffer',
                timeout: 30000
            });
            imageBuffer = Buffer.from(response.data);
        } else if (resultData && resultData.path) {
            // Has path property
            const fileUrl = `https://yisol-idm-vton.hf.space/file=${resultData.path}`;
            console.log('   Downloading from result.path...');
            const response = await axios.get(fileUrl, {
                responseType: 'arraybuffer',
                timeout: 30000
            });
            imageBuffer = Buffer.from(response.data);
        } else if (resultData && resultData.name) {
            // Gradio file object with name
            const fileUrl = `https://yisol-idm-vton.hf.space/file=${resultData.name}`;
            console.log('   Downloading from result.name...');
            const response = await axios.get(fileUrl, {
                responseType: 'arraybuffer',
                timeout: 30000
            });
            imageBuffer = Buffer.from(response.data);
        } else {
            // Log full result for debugging
            console.log('   Full result:', JSON.stringify(result).substring(0, 500));
            throw new Error('Could not extract image from result format');
        }

        console.log('   ✅ Try-on image retrieved!');
        console.log('   Image size:', (imageBuffer.length / 1024).toFixed(2), 'KB');
        
        return imageBuffer;

    } catch (error) {
        console.error('   ❌ IDM-VTON Error:', error.message);
        console.error('   Stack:', error.stack ? error.stack.split('\n')[0] : 'No stack');
        
        // Provide helpful error messages
        if (error.message.includes('Space is building')) {
            throw new Error('IDM-VTON Space is starting. Please wait 2-3 minutes and try again.');
        } else if (error.message.includes('queue')) {
            throw new Error('IDM-VTON is busy. Please try again in 30 seconds.');
        } else if (error.message.includes('timeout')) {
            throw new Error('Request timed out. Try again.');
        }
        
        throw error;
    }
};

/**
 * Process multiple dresses
 */
const processMultipleTryOns = async (userImagePath, dressImagePaths) => {
    const results = [];
    
    console.log(`\n🎨 Processing ${dressImagePaths.length} IDM-VTON try-ons...`);
    console.log('⚠️  First request may take 2-3 minutes\n');

    for (let i = 0; i < dressImagePaths.length; i++) {
        try {
            console.log(`[${i + 1}/${dressImagePaths.length}] Processing dress...`);
            
            const buffer = await processSingleTryOn(userImagePath, dressImagePaths[i]);
            
            // Save result
            const outputDir = './uploads/tryon-results';
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }

            const timestamp = Date.now();
            const filename = `tryon-${timestamp}-${i}.jpg`;
            const outputPath = path.join(outputDir, filename);
            
            fs.writeFileSync(outputPath, buffer);

            results.push({
                success: true,
                dressIndex: i,
                resultUrl: `/uploads/tryon-results/${filename}`,
                dressImagePath: dressImagePaths[i],
                aiGenerated: true,
                method: 'IDM-VTON AI'
            });

            console.log(`   ✅ Dress ${i + 1} completed!\n`);

        } catch (error) {
            console.error(`   ❌ Failed:`, error.message, '\n');
            
            results.push({
                success: false,
                dressIndex: i,
                error: error.message,
                dressImagePath: dressImagePaths[i],
                aiGenerated: false
            });
        }

        // Wait between requests
        if (i < dressImagePaths.length - 1) {
            console.log('   ⏳ Waiting 5 seconds...\n');
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }

    return results;
};

/**
 * Fallback mode
 */
const simpleTryOnFallback = async (userImagePath, dressImagePath) => {
    const dressBuffer = fs.readFileSync(dressImagePath);
    
    const outputDir = './uploads/tryon-results';
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    const timestamp = Date.now();
    const filename = `tryon-fallback-${timestamp}.jpg`;
    const outputPath = path.join(outputDir, filename);
    
    fs.writeFileSync(outputPath, dressBuffer);

    return {
        success: true,
        resultUrl: `/uploads/tryon-results/${filename}`,
        note: 'Fallback mode',
        aiGenerated: false
    };
};

/**
 * Check Space availability
 */
const checkAPIAvailability = async () => {
    if (!HF_API_KEY || HF_API_KEY.length < 10) {
        console.log('⚠️  No API key\n');
        return false;
    }

    try {
        console.log('🔍 Checking IDM-VTON Space...');
        const client = await Client.connect(SPACE_URL, { hf_token: HF_API_KEY });
        console.log('✅ IDM-VTON Space is ready!\n');
        return true;
    } catch (error) {
        console.log('⚠️  Space check failed\n');
        return false;
    }
};

module.exports = {
    processSingleTryOn,
    processMultipleTryOns,
    simpleTryOnFallback,
    checkAPIAvailability
};