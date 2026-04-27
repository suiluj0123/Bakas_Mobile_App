const express = require('express');
const pool = require('../../db');
const betModel = require('../models/betModel');
const groupModel = require('../models/groupModel');
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

    // 2. Ensure player is a member of all groups involved
    const uniqueGroupIds = [...new Set(tickets.map(t => t.groupId))];
    for (const groupId of uniqueGroupIds) {
      try {
        const group = await groupModel.getGroupById(groupId);
        if (group) {
          await groupModel.addMember({
            pgroup_code: group.pgroup_code,
            player_id: playerId,
            player_name: '', // Optional: can be fetched if needed
            name: group.name,
            desc: group.desc,
            status: 'active',
            created_by: playerId
          });
        }
      } catch (groupJoinErr) {
        console.error('[Betting] Error auto-joining group:', groupJoinErr.message);
      }
    }

    for (const ticket of tickets) {
      const count = Array.isArray(ticket.numbers) ? ticket.numbers.length : 0;
      // Map selection count to database system_id
      let systemId = 8; // Default Private/Standard
      if (count === 7) systemId = 1;
      else if (count === 8) systemId = 2;
      else if (count === 9) systemId = 3;
      else if (count === 10) systemId = 4;
      else if (count === 11) systemId = 5;
      else if (count === 12) systemId = 6;

      await betModel.createBet({
        player_id: playerId,
        group_id: ticket.groupId,
        system_id: systemId,
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

router.post('/bakas-public', async (req, res) => {
  try {
    const { playerId, groupId, requestedShares } = req.body;

    if (!playerId || !groupId || !requestedShares) {
      return res.status(400).json({ ok: false, message: 'Missing required fields' });
    }

    // 1. Fetch Group Details
    const group = await groupModel.getGroupById(groupId);
    if (!group) {
      return res.status(404).json({ ok: false, message: 'Group not found' });
    }

    // 2. Validate availability
    const availableShares = (group.target_bets || 0) - (group.total_bets || 0);
    if (requestedShares > availableShares) {
      return res.status(400).json({ ok: false, message: `Only ${availableShares} shares left in this group` });
    }

    // 3. Validate player limit (max_per)
    // For now we assume a simple check, in a real app we'd query total shares already bought by this player
    // But since "ui for now", let's proceed to balance deduction.

    // 4. Deduct Balance
    const pricePerShare = Number(group.price_per_share || 0);
    const result = await paymentModel.deductBalanceForBet({
      playerId,
      amount: pricePerShare,
      ticketCount: requestedShares
    });

    // 5. Update Group Total
    await groupModel.incrementTotalBets(groupId, requestedShares);

    let fixedNumbers = [];
    try {
      fixedNumbers = (typeof group.gen_numbers === 'string') ? JSON.parse(group.gen_numbers) : group.gen_numbers;
    } catch (e) {
      fixedNumbers = (group.gen_numbers || "").split(',').map(n => n.trim());
    }

    let drawId = group.drawdate_id;
    let lotteryId = 1;

    let validDraw = null;
    if (drawId) {
      const [rows] = await pool.execute('SELECT id, lottery_id FROM draws WHERE id = ? AND deleted_at IS NULL', [drawId]);
      if (rows.length > 0) {
        validDraw = rows[0];
        lotteryId = validDraw.lottery_id;
      }
    }

    if (!validDraw) {

      const guessLotteryId = group.lottery_id_game || 1; 
      const [upcomingDraws] = await pool.execute(
        `SELECT id, lottery_id FROM draws 
         WHERE (lottery_id = ? OR 1=1) AND deleted_at IS NULL AND status = 'upcoming'
         ORDER BY draw_date ASC, id DESC LIMIT 1`,
        [guessLotteryId]
      );

      if (upcomingDraws.length > 0) {
        drawId = upcomingDraws[0].id;
        lotteryId = upcomingDraws[0].lottery_id;
      } else {
        return res.status(400).json({ ok: false, message: 'No active draw found. Please contact the administrator.' });
      }
    }

    await betModel.createBet({
      player_id: playerId,
      group_id: groupId,
      system_id: group.system_id || 1,
      lotterytype_id: lotteryId, // Now stores the ACTUAL game ID (e.g. 6/42)
      drawdate_id: drawId,
      no_of_bets: requestedShares,
      amount: pricePerShare * requestedShares,
      selected_numbers: fixedNumbers,
      created_by: playerId
    });

    res.json({ ok: true, message: 'Bakas successful', newBalance: result.newBalance });
  } catch (error) {
    console.error('[Betting] Bakas error:', error.message);
    res.status(500).json({ ok: false, message: error.message });
  }
});

module.exports = router;
