const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directory exists
const uploadDir = path.join(__dirname, '../../uploads/ids');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const profileDir = path.join(__dirname, '../../uploads/profiles');
if (!fs.existsSync(profileDir)) {
  fs.mkdirSync(profileDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Security: Sanitize filename and add timestamp to avoid collisions
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, 'id-' + uniqueSuffix + ext);
  },
});

const fileFilter = (req, file, cb) => {
  // Security: Only allow specific image types
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG and WEBP are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // Security: 5MB limit
  },
});

module.exports = {
  uploadIdPhoto: upload.fields([
    { name: 'id_photo', maxCount: 1 },
    { name: 'selfie_photo', maxCount: 1 },
  ]),
  uploadProfilePhotos: multer({
    storage: multer.diskStorage({
      destination: (req, file, cb) => {
        cb(null, profileDir);
      },
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const prefix = file.fieldname === 'profile_photo' ? 'profile-' : 'id-';
        cb(null, prefix + uniqueSuffix + path.extname(file.originalname));
      },
    }),
    fileFilter: fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 },
  }).fields([
    { name: 'profile_photo', maxCount: 1 },
    { name: 'id_photo', maxCount: 1 },
  ]),
};
