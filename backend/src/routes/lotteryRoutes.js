const express = require('express');
const lotteryModel = require('../models/lotteryModel');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const lotteries = await lotteryModel.getAllLotteries();
    res.json({ ok: true, data: lotteries });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const result = await lotteryModel.createLottery(req.body);
    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

module.exports = router;
