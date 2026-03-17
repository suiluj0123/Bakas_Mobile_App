const pool = require('../../db');

async function createBet({ player_id, group_id, system_id, lotterytype_id, drawdate_id, no_of_bets, amount, selected_numbers, created_by }) {
  const [result] = await pool.execute(
    `INSERT INTO bets 
      (player_id, group_id, system_id, lotterytype_id, drawdate_id, no_of_bets, amount, selected_numbers, status, created_by, updated_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, NOW(), NOW())`,
    [player_id, group_id, system_id, lotterytype_id, drawdate_id, no_of_bets, amount, JSON.stringify(selected_numbers), created_by, created_by]
  );
  return { id: result.insertId };
}

async function getBetsByPlayer(playerId) {
  const [rows] = await pool.execute(
    `SELECT b.*, l.name as lottery_name, d.draw_date
     FROM bets b
     LEFT JOIN lotteries l ON b.lotterytype_id = l.id
     LEFT JOIN draws d ON b.drawdate_id = d.id
     WHERE b.player_id = ? AND b.deleted_at IS NULL
     ORDER BY b.created_at DESC`,
    [playerId]
  );
  return rows.map(row => ({
    ...row,
    selected_numbers: row.selected_numbers ? JSON.parse(row.selected_numbers) : []
  }));
}

module.exports = {
  createBet,
  getBetsByPlayer
};
