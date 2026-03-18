require('dotenv').config();
const axios = require('axios');

const API_KEY = process.env.HUGGINGFACE_API_KEY;

console.log('Testing Hugging Face API...\n');

if (!API_KEY || API_KEY === 'hf_your_token_here') {
    console.error('ERROR: No API key found!');
    console.log('\nSteps to fix:');
    console.log('1. Go to https://huggingface.co/settings/tokens');
    console.log('2. Create a new token');
    console.log('3. Copy it (starts with hf_)');
    console.log('4. Add to .env: HUGGINGFACE_API_KEY=hf_your_token\n');
    process.exit(1);
}

console.log('API Key found:', API_KEY.substring(0, 10) + '...');

axios.get('https://api-inference.huggingface.co/models/yisol/IDM-VTON', {
    headers: { 'Authorization': `Bearer ${API_KEY}` },
    timeout: 10000
})
.then(response => {
    console.log('\nSUCCESS! API is working!');
    console.log('Status:', response.status);
})
.catch(error => {
    if (error.response) {
        console.error('\nERROR:', error.response.status);
        if (error.response.status === 401) {
            console.log('Invalid API key! Get a new one from:');
            console.log('https://huggingface.co/settings/tokens');
        } else if (error.response.status === 503) {
            console.log('Model is loading - wait 30 seconds and try again');
        }
    } else {
        console.error('\nConnection Error:', error.message);
    }
});