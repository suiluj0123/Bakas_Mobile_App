const operatorModel = require('../models/operatorModel');
const lotteryModel = require('../models/lotteryModel');
const drawModel = require('../models/drawModel');

async function login(req, res) {
  try {
    const { username, password } = req.body;
    const operator = await operatorModel.findOperatorByUsername(username);

    if (!operator || operator.password !== password) {
      return res.status(401).json({ ok: false, message: 'Invalid credentials' });
    }

    res.json({ ok: true, data: { id: operator.id, username: operator.user_name, role: 'operator' } });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function createLottery(req, res) {
  try {
    const result = await lotteryModel.createLottery(req.body);
    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function updateLottery(req, res) {
  try {
    const { id } = req.params;
    const success = await lotteryModel.updateLottery(id, req.body);
    res.json({ ok: success, message: success ? 'Lottery updated' : 'Update failed' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function createDraw(req, res) {
  try {
    const result = await drawModel.createDraw(req.body);
    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function updateDraw(req, res) {
  try {
    const { id } = req.params;
    const success = await drawModel.updateDraw(id, req.body);
    res.json({ ok: success, message: success ? 'Draw updated' : 'Update failed' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = {
  login,
  createLottery,
  updateLottery,
  createDraw,
  updateDraw
};
