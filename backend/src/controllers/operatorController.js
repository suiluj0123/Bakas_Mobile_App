const operatorModel = require('../models/operatorModel');
const lotteryModel = require('../models/lotteryModel');
const drawModel = require('../models/drawModel');
const notificationModel = require('../models/notificationModel');

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
    const { lottery_id, name: receivedName } = req.body;
    
    // Fetch lottery to get the actual name
    const lottery = await lotteryModel.getLotteryById(lottery_id);
    const actualName = lottery ? lottery.name : (receivedName || `Draw for ${lottery_id}`);
    
    // Ensure we use the actual name for creation
    const drawData = { ...req.body, name: actualName };
    const result = await drawModel.createDraw(drawData);

    // Broadcast notification to all players for the new upcoming game
    try {
      const drawDate = req.body.draw_date
        ? new Date(req.body.draw_date).toLocaleString('en-PH', {
            timeZone: 'Asia/Manila',
            year: 'numeric', month: 'long', day: 'numeric',
            hour: '2-digit', minute: '2-digit'
          })
        : 'a scheduled date';

      await notificationModel.broadcastNotification(
        'Upcoming Lotto Game!',
        `A new draw "${actualName}" is scheduled on ${drawDate}. Don't miss it — place your bets now!`,
        'upcoming'
      );
    } catch (notifErr) {
      console.error('Notification broadcast failed:', notifErr.message);
    }

    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function updateDraw(req, res) {
  try {
    const { id } = req.params;
    const { lottery_id, name: receivedName } = req.body;

    // Fetch lottery to get the actual name if lottery_id is provided
    let actualName = receivedName;
    if (lottery_id) {
      const lottery = await lotteryModel.getLotteryById(lottery_id);
      if (lottery) {
        actualName = lottery.name;
      }
    }

    const updateData = { ...req.body, name: actualName };
    const success = await drawModel.updateDraw(id, updateData);
    res.json({ ok: success, message: success ? 'Draw updated' : 'Update failed' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function deleteLottery(req, res) {
  try {
    const { id } = req.params;
    const success = await lotteryModel.deleteLottery(id);
    res.json({ ok: success, message: success ? 'Lottery deleted' : 'Delete failed' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = {
  login,
  createLottery,
  updateLottery,
  createDraw,
  updateDraw,
  deleteLottery
};
