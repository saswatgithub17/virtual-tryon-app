// FILE UPLOAD MIDDLEWARE — Multer
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
['./uploads/dresses', './uploads/user-photos', './uploads/tryon-results', './uploads/receipts'].forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// Storage for dress images
const dressStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, './uploads/dresses'),
  filename: (_req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `dress-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

// Storage for user photos (try-on)
const userPhotoStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, './uploads/user-photos'),
  filename: (_req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `user-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

// Accept images only
const imageFilter = (_req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extOk = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimeOk = allowedTypes.test(file.mimetype);
  if (extOk && mimeOk) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp)'));
  }
};

// Fix 10: raise limit to 10MB to match Flutter camera_service.dart (was 5MB).
// Flutter's CameraService validates up to 10MB before sending — mismatched
// limits caused large photos to pass client validation then be silently
// rejected by the server, leaving try-on with no useful error message.
const FILE_SIZE_LIMIT = 10 * 1024 * 1024; // 10MB

const uploadDressImage = multer({
  storage: dressStorage,
  limits: { fileSize: FILE_SIZE_LIMIT },
  fileFilter: imageFilter
}).single('image');

const uploadUserPhoto = multer({
  storage: userPhotoStorage,
  limits: { fileSize: FILE_SIZE_LIMIT },
  fileFilter: imageFilter
}).single('userPhoto');

// Multer error handler
const handleUploadError = (err, _req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: `File too large. Maximum size is ${FILE_SIZE_LIMIT / (1024 * 1024)}MB.`
      });
    }
    return res.status(400).json({ success: false, message: err.message });
  } else if (err) {
    return res.status(400).json({ success: false, message: err.message });
  }
  next();
};

module.exports = { uploadDressImage, uploadUserPhoto, handleUploadError };