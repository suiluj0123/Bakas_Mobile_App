const express = require('express');
const { login, register } = require('../controllers/authController');
const { googleLogin } = require('../controllers/googleAuthController');
const { verifyGoogleToken } = require('../middleware/googleAuth');

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/auth/google', verifyGoogleToken, googleLogin);

module.exports = router;

