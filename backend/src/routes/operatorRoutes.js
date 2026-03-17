const express = require('express');
const operatorController = require('../controllers/operatorController');
const router = express.Router();

router.post('/login', operatorController.login);

// Lottery Management
router.post('/lotteries', operatorController.createLottery);
router.put('/lotteries/:id', operatorController.updateLottery);

// Draw Management
router.post('/draws', operatorController.createDraw);
router.put('/draws/:id', operatorController.updateDraw);

module.exports = router;
