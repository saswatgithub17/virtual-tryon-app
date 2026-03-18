// =============================================
// TEST HUGGING FACE API CONNECTION
// Run: node testHuggingFace.js
// =============================================

require('dotenv').config();
const axios = require('axios');

const API_KEY = process.env.HUGGINGFACE_API_KEY;

console.log('🧪 Testing Hugging Face API Connection...\n');

// Check if API key exists
if (!API_KEY || API_KEY === 'hf_your_token_here') {
    console.error('❌ ERROR: No valid API key found in .env file');
    console.log('\n📋 Steps to fix:');
    console.log('1. Go to https://huggingface.co/settings/tokens');
    console.log('2. Create a new token (free account)');
    console.log('3. Copy the token (starts with hf_)');
    console.log('4. Update .env: HUGGINGFACE_API_KEY=hf_your_actual_token');
    console.log('5. Restart server and run this test again\n');
    process.exit(1);
}

console.log('✅ API Key found in .env');
console.log(`   Key: ${API_KEY.substring(0, 10)}...${API_KEY.substring(API_KEY.length - 5)}\n`);

// Test 1: Check API availability
console.log('📡 Test 1: Checking API availability...');

const testAPI = async () => {
    try {
        const response = await axios.get(
            'https://api-inference.huggingface.co/models/yisol/IDM-VTON',
            {
                headers: {
                    'Authorization': `Bearer ${API_KEY}`
                },
                timeout: 10000
            }
        );

        console.log('✅ API is accessible');
        console.log(`   Status: ${response.status}`);
        
        // Check if model is loaded
        if (response.data && response.data.error) {
            console.log(`⚠️  Model status: ${response.data.error}`);
            if (response.data.error.includes('loading')) {
                console.log('   The model is loading. This is normal for first use.');
                console.log('   Wait 20-30 seconds and try again.');
            }
        } else {
            console.log('✅ Model is ready!\n');
        }

        return true;

    } catch (error) {
        if (error.response) {
            console.error('❌ API Error:', error.response.status);
            console.error('   Message:', error.response.data);
            
            if (error.response.status === 401) {
                console.log('\n❌ AUTHENTICATION FAILED');
                console.log('   Your API key is invalid or expired.');
                console.log('   Please get a new key from: https://huggingface.co/settings/tokens\n');
            } else if (error.response.status === 503) {
                console.log('\n⚠️  MODEL IS LOADING');
                console.log('   This is normal for first use.');
                console.log('   Wait 20-30 seconds and try the try-on endpoint again.\n');
            }
        } else if (error.code === 'ECONNREFUSED') {
            console.error('❌ Connection Refused');
            console.error('   Cannot reach Hugging Face servers.');
            console.error('   Check your internet connection.\n');
        } else {
            console.error('❌ Error:', error.message);
        }
        return false;
    }
};

// Run test
testAPI().then(success => {
    if (success) {
        console.log('🎉 SUCCESS! Hugging Face API is working!');
        console.log('\n📋 Next steps:');
        console.log('1. Make sure your server is running (npm run dev)');
        console.log('2. Try the try-on endpoint in Postman');
        console.log('3. First request may take 30-60 seconds (model loading)');
        console.log('4. Subsequent requests will be faster\n');
    } else {
        console.log('\n❌ API test failed. Please fix the issues above.\n');
    }
    process.exit(success ? 0 : 1);
});