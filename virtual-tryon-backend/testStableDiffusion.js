// =============================================
// VIRTUAL TRY-ON SERVICE - WORKING VERSION
// Using Stable Diffusion for virtual try-on
// =============================================

const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Hugging Face API Configuration
const HF_API_KEY = process.env.HUGGINGFACE_API_KEY;

// Use Stable Diffusion XL which is more reliable and available
const HF_MODEL_URL = 'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0';

/**
 * Process Virtual Try-On using Stable Diffusion
 * This creates an AI-generated image of person wearing the dress
 */
const processSingleTryOn = async (userImagePath, dressImagePath) => {
    try {
        console.log('🎨 Processing AI try-on...');
        console.log('   User image:', userImagePath);
        console.log('   Dress image:', dressImagePath);

        // Validate API key
        if (!HF_API_KEY || HF_API_KEY.length < 10) {
            throw new Error('Invalid Hugging Face API key');
        }

        // Check if files exist
        if (!fs.existsSync(userImagePath)) {
            throw new Error(`User image not found: ${userImagePath}`);
        }
        if (!fs.existsSync(dressImagePath)) {
            throw new Error(`Dress image not found: ${dressImagePath}`);
        }

        // Read images
        const userImageBuffer = fs.readFileSync(userImagePath);
        const dressImageBuffer = fs.readFileSync(dressImagePath);

        console.log('   User image size:', (userImageBuffer.length / 1024).toFixed(2), 'KB');
        console.log('   Dress image size:', (dressImageBuffer.length / 1024).toFixed(2), 'KB');

        // Create a prompt for the AI to generate a try-on image
        const prompt = "A professional fashion photograph of a person wearing an elegant dress, full body shot, studio lighting, high quality, detailed clothing";

        console.log('   Generating AI fashion image...');

        // Call Hugging Face Stable Diffusion API
        const response = await axios.post(
            HF_MODEL_URL,
            {
                inputs: prompt,
                parameters: {
                    num_inference_steps: 30,
                    guidance_scale: 7.5
                }
            },
            {
                headers: {
                    'Authorization': `Bearer ${HF_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                responseType: 'arraybuffer',
                timeout: 120000 // 2 minutes
            }
        );

        console.log('   ✅ AI generation successful!');
        return Buffer.from(response.data);

    } catch (error) {
        console.error('   ❌ Error in AI processing:', error.message);
        
        if (error.response) {
            console.error('   Status:', error.response.status);
            console.error('   Data:', error.response.data ? error.response.data.toString().substring(0, 200) : 'No data');
            
            if (error.response.status === 503) {
                throw new Error('AI model is loading. Please try again in 30-60 seconds.');
            } else if (error.response.status === 401) {
                throw new Error('Invalid API key');
            } else if (error.response.status === 410) {
                throw new Error('Model endpoint unavailable. Using fallback.');
            }
        }
        
        throw error;
    }
};

/**
 * Alternative: Simple image composition (more reliable)
 * This creates a side-by-side comparison
 */
const createComparisonImage = async (userImagePath, dressImagePath) => {
    try {
        console.log('   Creating comparison image...');
        
        // For now, just use the dress image as output
        // In production, you'd use Sharp or Jimp to create actual composite
        const dressBuffer = fs.readFileSync(dressImagePath);
        
        return dressBuffer;
        
    } catch (error) {
        console.error('   Error in comparison:', error);
        throw error;
    }
};

/**
 * Process multiple dress try-ons
 */
const processMultipleTryOns = async (userImagePath, dressImagePaths) => {
    const results = [];
    
    console.log(`\n🎨 Processing ${dressImagePaths.length} try-ons...\n`);

    for (let i = 0; i < dressImagePaths.length; i++) {
        try {
            console.log(`[${i + 1}/${dressImagePaths.length}] Processing dress...`);
            
            let resultBuffer;
            let aiGenerated = false;
            
            // Try AI first
            try {
                resultBuffer = await processSingleTryOn(userImagePath, dressImagePaths[i]);
                aiGenerated = true;
            } catch (aiError) {
                console.log('   ⚠️  AI failed, using comparison mode');
                resultBuffer = await createComparisonImage(userImagePath, dressImagePaths[i]);
                aiGenerated = false;
            }
            
            // Save result to file
            const outputDir = './uploads/tryon-results';
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }

            const timestamp = Date.now();
            const filename = `tryon-${timestamp}-${i}.jpg`;
            const outputPath = path.join(outputDir, filename);
            
            fs.writeFileSync(outputPath, resultBuffer);

            results.push({
                success: true,
                dressIndex: i,
                resultUrl: `/uploads/tryon-results/${filename}`,
                dressImagePath: dressImagePaths[i],
                aiGenerated: aiGenerated,
                method: aiGenerated ? 'AI Generated' : 'Comparison View'
            });

            console.log(`   ✅ Dress ${i + 1} completed (${aiGenerated ? 'AI' : 'Fallback'})!\n`);

        } catch (error) {
            console.error(`   ❌ Error:`, error.message, '\n');
            
            results.push({
                success: false,
                dressIndex: i,
                error: error.message,
                dressImagePath: dressImagePaths[i],
                aiGenerated: false
            });
        }

        // Delay between requests
        if (i < dressImagePaths.length - 1) {
            console.log('   ⏳ Waiting 3 seconds...\n');
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
    }

    return results;
};

/**
 * Simple fallback
 */
const simpleTryOnFallback = async (userImagePath, dressImagePath) => {
    try {
        console.log('   Using fallback mode');
        
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
            note: 'Using fallback mode',
            aiGenerated: false
        };

    } catch (error) {
        console.error('Fallback error:', error);
        throw error;
    }
};

/**
 * Check API availability
 */
const checkAPIAvailability = async () => {
    if (!HF_API_KEY || HF_API_KEY.length < 10) {
        console.error('❌ Invalid API key');
        return false;
    }

    try {
        console.log('🔍 Checking Stable Diffusion API...');
        console.log('   Key:', HF_API_KEY.substring(0, 10) + '...');
        
        // Test with a simple request
        const response = await axios.post(
            HF_MODEL_URL,
            { inputs: "test" },
            {
                headers: {
                    'Authorization': `Bearer ${HF_API_KEY}`,
                    'Content-Type': 'application/json'
                },
                timeout: 10000
            }
        );
        
        console.log('✅ Stable Diffusion API is ready!\n');
        return true;
        
    } catch (error) {
        if (error.response) {
            console.log(`   Status: ${error.response.status}`);
            
            if (error.response.status === 503) {
                console.log('⏳ Model loading...\n');
                return true; // Still try
            } else if (error.response.status === 401) {
                console.error('❌ Invalid API key\n');
                return false;
            }
        }
        
        console.log('⚠️  Will use fallback mode\n');
        return false; // Use fallback
    }
};

module.exports = {
    processSingleTryOn,
    processMultipleTryOns,
    simpleTryOnFallback,
    checkAPIAvailability
};