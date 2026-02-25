const historyModel = require('../models/historyModel');

/**
 * Fetch player transaction history
 */
async function getPlayerHistory(req, res) {
  try {
    const { playerId } = req.query;

    if (!playerId) {
      return res.status(400).json({
        ok: false,
        message: 'Player ID is required'
      });
    }

    const histories = await historyModel.getHistoryByPlayerId(playerId);

    res.status(200).json({
      ok: true,
      data: histories,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: error.message
    });
  }
}

module.exports = {
  getPlayerHistory,
};
