// =============================================
// COMPLETE DIAGNOSTIC CHECK
// Run: node diagnostic.js
// =============================================

require('dotenv').config();
const fs = require('fs');
const path = require('path');

console.log('🔍 VIRTUAL TRY-ON DIAGNOSTIC CHECK\n');
console.log('='.repeat(50));

// Check 1: Environment Variables
console.log('\n1️⃣ ENVIRONMENT VARIABLES:');
console.log('-'.repeat(50));

const API_KEY = process.env.HUGGINGFACE_API_KEY;
if (!API_KEY) {
    console.log('❌ HUGGINGFACE_API_KEY: NOT FOUND');
} else if (API_KEY === 'hf_your_token_here') {
    console.log('❌ HUGGINGFACE_API_KEY: Default placeholder (not set)');
} else if (API_KEY.length < 10) {
    console.log('❌ HUGGINGFACE_API_KEY: Too short (invalid)');
} else {
    console.log('✅ HUGGINGFACE_API_KEY: Found');
    console.log('   Value:', API_KEY.substring(0, 10) + '...' + API_KEY.substring(API_KEY.length - 5));
    console.log('   Length:', API_KEY.length);
}

// Check 2: Node Modules
console.log('\n2️⃣ REQUIRED PACKAGES:');
console.log('-'.repeat(50));

const packages = [
    'axios',
    'dotenv',
    'express',
    'mysql2',
    'multer',
    'form-data',
    '@gradio/client'
];

packages.forEach(pkg => {
    try {
        require.resolve(pkg);
        console.log(`✅ ${pkg}: Installed`);
    } catch (e) {
        console.log(`❌ ${pkg}: NOT INSTALLED`);
        console.log(`   Install: npm install ${pkg}`);
    }
});

// Check 3: File Structure
console.log('\n3️⃣ FILE STRUCTURE:');
console.log('-'.repeat(50));

const requiredFiles = [
    './services/tryonService.js',
    './controllers/tryonController.js',
    './uploads/dresses/dress1.jpg',
    './uploads/dresses/dress2.jpg'
];

requiredFiles.forEach(file => {
    if (fs.existsSync(file)) {
        const stats = fs.statSync(file);
        console.log(`✅ ${file}`);
        if (file.includes('.jpg')) {
            console.log(`   Size: ${(stats.size / 1024).toFixed(2)} KB`);
        }
    } else {
        console.log(`❌ ${file}: NOT FOUND`);
    }
});

// Check 4: Uploads Directory
console.log('\n4️⃣ UPLOADS DIRECTORY:');
console.log('-'.repeat(50));

const uploadDirs = [
    './uploads',
    './uploads/dresses',
    './uploads/user-photos',
    './uploads/tryon-results'
];

uploadDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir);
        console.log(`✅ ${dir}`);
        console.log(`   Files: ${files.length}`);
        if (dir === './uploads/dresses' && files.length > 0) {
            console.log('   Contents:', files.slice(0, 5).join(', '));
        }
    } else {
        console.log(`❌ ${dir}: NOT FOUND`);
        console.log(`   Create: mkdir ${dir}`);
    }
});

// Check 5: Database Connection
console.log('\n5️⃣ DATABASE:');
console.log('-'.repeat(50));

try {
    const db = require('./config/database');
    console.log('✅ Database config loaded');
    
    db.query('SELECT COUNT(*) as count FROM dresses', (err, results) => {
        if (err) {
            console.log('❌ Database query failed:', err.message);
        } else {
            console.log(`✅ Database connected`);
            console.log(`   Dresses in DB: ${results[0].count}`);
        }
    });
} catch (e) {
    console.log('❌ Database config error:', e.message);
}

// Check 6: Test API Connection
console.log('\n6️⃣ HUGGING FACE API TEST:');
console.log('-'.repeat(50));

const testAPI = async () => {
    if (!API_KEY || API_KEY.length < 10) {
        console.log('⚠️  Skipping (no valid API key)');
        return;
    }

    const axios = require('axios');
    
    // Test 1: Stable Diffusion (most reliable)
    console.log('\nTesting Stable Diffusion...');
    try {
        await axios.post(
            'https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5',
            { inputs: "test" },
            {
                headers: { 'Authorization': `Bearer ${API_KEY}` },
                timeout: 10000
            }
        );
        console.log('✅ Stable Diffusion: WORKING');
    } catch (e) {
        console.log('❌ Stable Diffusion:', e.response?.status || e.message);
    }
    
    // Test 2: Gradio Client
    console.log('\nTesting Gradio Client...');
    try {
        const { Client } = require('@gradio/client');
        console.log('✅ Gradio Client: Installed');
        
        // Try connecting to IDM-VTON Space
        console.log('   Connecting to IDM-VTON Space...');
        const client = await Client.connect("yisol/IDM-VTON", {
            hf_token: API_KEY
        });
        console.log('✅ IDM-VTON Space: ACCESSIBLE');
    } catch (e) {
        console.log('❌ IDM-VTON Space:', e.message);
        if (e.message.includes('building')) {
            console.log('   Status: Space is starting (wait 2-3 minutes)');
        }
    }
};

setTimeout(() => {
    testAPI().then(() => {
        console.log('\n' + '='.repeat(50));
        console.log('🎯 DIAGNOSTIC COMPLETE');
        console.log('='.repeat(50));
        console.log('\nShare this output for troubleshooting!\n');
        process.exit(0);
    });
}, 2000);