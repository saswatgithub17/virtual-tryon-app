// =============================================
// UPDATE DRESS IMAGES SCRIPT
// Helper to update dress image URLs in database
// =============================================

const db = require('./config/database');

// Update dress image URLs to point to actual files
// You'll need to download sample dress images and place them in uploads/dresses/

const updateDressImages = () => {
    const updates = [
        { dress_id: 1, image_url: '/uploads/dresses/dress1.jpg' },
        { dress_id: 2, image_url: '/uploads/dresses/dress2.jpg' },
        { dress_id: 3, image_url: '/uploads/dresses/dress3.jpg' },
        { dress_id: 4, image_url: '/uploads/dresses/dress4.jpg' },
        { dress_id: 5, image_url: '/uploads/dresses/dress5.jpg' },
        { dress_id: 6, image_url: '/uploads/dresses/dress6.jpg' },
        { dress_id: 7, image_url: '/uploads/dresses/dress7.jpg' },
        { dress_id: 8, image_url: '/uploads/dresses/dress8.jpg' }
    ];

    console.log('📝 Updating dress image URLs...');

    updates.forEach(update => {
        const query = 'UPDATE dresses SET image_url = ? WHERE dress_id = ?';
        
        db.query(query, [update.image_url, update.dress_id], (err, result) => {
            if (err) {
                console.error(`❌ Error updating dress ${update.dress_id}:`, err);
            } else {
                console.log(`✅ Updated dress ${update.dress_id}: ${update.image_url}`);
            }
        });
    });

    setTimeout(() => {
        console.log('\n✅ All updates completed!');
        console.log('\n📋 Next steps:');
        console.log('1. Download sample dress images from Google/Pinterest');
        console.log('2. Save them as dress1.jpg, dress2.jpg, etc.');
        console.log('3. Place them in: uploads/dresses/');
        console.log('4. Test the try-on endpoint!');
        
        process.exit(0);
    }, 2000);
};

updateDressImages();