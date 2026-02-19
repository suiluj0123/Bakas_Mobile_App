const paymentModel = require('../models/paymentModel');

async function getWalletStats(req, res) {
  try {
    const { playerId } = req.query;

    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'Player ID is required' });
    }

    const stats = await paymentModel.getPlayerWalletStats(playerId);

    if (!stats) {
      return res.status(404).json({ ok: false, message: 'Player profile not found. Please contact support.' });
    }

    const balance = Number(stats.credit || 0);
    const cashInLimit = Number(stats.cash_in_limit || 0);

    res.status(200).json({
      ok: true,
      data: {
        balance,
        cashInLimit,
      },
    });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function processTransaction(req, res) {
  try {

    const { playerId, type, amount, paymentMethod, provider } = req.body;

    if (!playerId || !type || !amount || !paymentMethod) {
      return res.status(400).json({ ok: false, message: 'Missing required fields' });
    }

    if (amount <= 0) {
      return res.status(400).json({ ok: false, message: 'Amount must be greater than zero' });
    }

    const stats = await paymentModel.getPlayerWalletStats(playerId);
    if (!stats) {
      return res.status(404).json({ ok: false, message: 'Player not found' });
    }

    const effectiveLimit = Number(stats.cash_in_limit || 0);
    const currentCredit = Number(stats.credit || 0);

    if (type === 'CASH_OUT' && currentCredit < amount) {
      return res.status(400).json({ ok: false, message: 'Insufficient balance' });
    }

    if (type === 'CASH_IN' && effectiveLimit < amount) {
      return res.status(400).json({ ok: false, message: 'Cash in limit exceeded' });
    }

    const fee = 0;

    const transactionId = await paymentModel.createTransaction({
      playerId,
      type,
      amount,
      fee,
      paymentMethod,
      provider,
    });

    res.status(200).json({
      ok: true,
      message: 'Transaction processed successfully',
      data: { transactionId },
    });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = {
  getWalletStats,
  processTransaction,
};
