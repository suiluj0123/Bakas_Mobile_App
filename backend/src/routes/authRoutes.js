const express = require('express');
const { login, register, forgotPassword, resetPassword, searchPlayers } = require('../controllers/authController');
const { googleLogin } = require('../controllers/googleAuthController');
const { verifyGoogleToken } = require('../middleware/googleAuth');

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/auth/google', verifyGoogleToken, googleLogin);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.get('/players/search', searchPlayers);

module.exports = router;

