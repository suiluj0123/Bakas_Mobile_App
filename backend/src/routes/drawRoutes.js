const express = require('express');
const drawModel = require('../models/drawModel');
const router = express.Router();

router.get('/upcoming', async (req, res) => {
  try {
    const draws = await drawModel.getUpcomingDraws();
    res.json({ ok: true, data: draws });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.get('/results', async (req, res) => {
  try {
    const results = await drawModel.getDrawResults();
    res.json({ ok: true, data: results });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const draw = await drawModel.getDrawById(req.params.id);
    if (!draw) return res.status(404).json({ ok: false, message: 'Draw not found' });
    res.json({ ok: true, data: draw });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const result = await drawModel.createDraw(req.body);
    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const success = await drawModel.updateDraw(req.params.id, req.body);
    if (!success) return res.status(404).json({ ok: false, message: 'Draw not found' });
    res.json({ ok: true, message: 'Draw updated' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const success = await drawModel.deleteDraw(req.params.id);
    if (!success) return res.status(404).json({ ok: false, message: 'Draw not found' });
    res.json({ ok: true, message: 'Draw deleted' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

module.exports = router;
