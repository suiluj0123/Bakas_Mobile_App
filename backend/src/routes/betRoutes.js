const express = require('express');
const betModel = require('../models/betModel');
const router = express.Router();

router.get('/player/:playerId', async (req, res) => {
  try {
    const { playerId } = req.params;
    const bets = await betModel.getBetsByPlayer(playerId);
    res.json({ ok: true, data: bets });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const result = await betModel.createBet(req.body);
    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

const paymentModel = require('../models/paymentModel');

router.post('/create-tickets', async (req, res) => {
  try {
    const { playerId, tickets, amountPerTicket } = req.body;

    if (!playerId || !tickets || !Array.isArray(tickets)) {
      return res.status(400).json({ ok: false, message: 'Invalid request data' });
    }

    // 1. Deduct balance
    const result = await paymentModel.deductBalanceForBet({
      playerId,
      amount: amountPerTicket,
      ticketCount: tickets.length
    });

    // 2. Create tickets (bets)
    for (const ticket of tickets) {
      await betModel.createBet({
        player_id: playerId,
        group_id: ticket.groupId,
        system_id: 1, // Default
        lotterytype_id: ticket.lotteryId,
        drawdate_id: ticket.drawId,
        no_of_bets: 1,
        amount: amountPerTicket,
        selected_numbers: ticket.numbers,
        created_by: playerId
      });
    }

    res.json({ ok: true, message: 'Tickets created successfully', newBalance: result.newBalance });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

module.exports = router;
