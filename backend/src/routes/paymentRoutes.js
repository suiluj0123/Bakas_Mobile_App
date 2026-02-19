const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

router.get('/api/payments/stats', paymentController.getWalletStats);
router.post('/api/payments/transaction', paymentController.processTransaction);

module.exports = router;
