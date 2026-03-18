// =============================================
// FILE UPLOAD MIDDLEWARE
// Using Multer for image uploads
// =============================================

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Create uploads directory if it doesn't exist
const uploadsDir = './uploads/dresses';
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const userPhotosDir = './uploads/user-photos';
if (!fs.existsSync(userPhotosDir)) {
    fs.mkdirSync(userPhotosDir, { recursive: true });
}

const tryonResultsDir = './uploads/tryon-results';
if (!fs.existsSync(tryonResultsDir)) {
    fs.mkdirSync(tryonResultsDir, { recursive: true });
}

// Configure storage for dress images
const dressStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'dress-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Configure storage for user photos (try-on)
const userPhotoStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, userPhotosDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'user-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// File filter - only accept images
const imageFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (extname && mimetype) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp)'));
    }
};

// Multer configuration for dress images
const uploadDressImage = multer({
    storage: dressStorage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    },
    fileFilter: imageFilter
}).single('image');

// Multer configuration for user photos
const uploadUserPhoto = multer({
    storage: userPhotoStorage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    },
    fileFilter: imageFilter
}).single('userPhoto');

// Error handling middleware for multer
const handleUploadError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                success: false,
                message: 'File size is too large. Maximum size is 5MB.'
            });
        }
        return res.status(400).json({
            success: false,
            message: err.message
        });
    } else if (err) {
        return res.status(400).json({
            success: false,
            message: err.message
        });
    }
    next();
};

module.exports = {
    uploadDressImage,
    uploadUserPhoto,
    handleUploadError
};