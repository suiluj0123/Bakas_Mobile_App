const express = require('express');
const router = express.Router();
const historyController = require('../controllers/historyController');

// GET /history?playerId=123
router.get('/history', historyController.getPlayerHistory);

module.exports = router;
