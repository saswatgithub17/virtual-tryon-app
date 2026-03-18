// =============================================
// TEST IDM-VTON SPACE CONNECTION
// Run: node testIDMVTON.js
// =============================================

require('dotenv').config();
const { Client } = require("@gradio/client");

const API_KEY = process.env.HUGGINGFACE_API_KEY;
const SPACE_URL = "yisol/IDM-VTON";

console.log('🧪 Testing IDM-VTON Space Connection...\n');

if (!API_KEY || API_KEY.length < 10) {
    console.error('❌ ERROR: No API key found!');
    console.log('\nAdd to .env: HUGGINGFACE_API_KEY=hf_your_key\n');
    process.exit(1);
}

console.log('API Key:', API_KEY.substring(0, 10) + '...');
console.log('Space:', SPACE_URL, '\n');

const testSpace = async () => {
    try {
        console.log('Connecting to IDM-VTON Space...');
        console.log('(This may take 2-3 minutes if Space is cold starting)\n');
        
        const client = await Client.connect(SPACE_URL, {
            hf_token: API_KEY
        });
        
        console.log('✅ SUCCESS! Connected to IDM-VTON Space!');
        console.log('\nSpace is accessible and ready to use.\n');
        
        console.log('📋 Next steps:');
        console.log('1. Install Gradio client: npm install @gradio/client');
        console.log('2. Replace tryonService.js with tryonService_IDM_VTON.js');
        console.log('3. Restart server');
        console.log('4. Test try-on endpoint in Postman\n');
        
        return true;
        
    } catch (error) {
        console.error('❌ Connection failed:', error.message, '\n');
        
        if (error.message.includes('Space is building')) {
            console.log('⏳ The Space is starting up (cold start)');
            console.log('   This happens when the Space hasn\'t been used recently');
            console.log('   Wait 2-3 minutes and run this test again\n');
            return false;
        }
        
        if (error.message.includes('401')) {
            console.log('❌ Invalid API key');
            console.log('   Get new key from: https://huggingface.co/settings/tokens\n');
            return false;
        }
        
        console.log('⚠️  Space might be temporarily unavailable');
        console.log('   Try again in a few minutes\n');
        return false;
    }
};

testSpace().then(success => {
    process.exit(success ? 0 : 1);
});