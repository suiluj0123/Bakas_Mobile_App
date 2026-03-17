const pool = require('../../db');

async function createDraw({ name, lottery_id, draw_date, cutoff_date, created_by, status }) {
  const drawStatus = status || 'upcoming';
  const [result] = await pool.execute(
    `INSERT INTO draws 
      (name, lottery_id, draw_date, cutoff_date, status, created_by, updated_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
    [name, lottery_id, draw_date, cutoff_date, drawStatus, created_by, created_by]
  );
  return { id: result.insertId };
}

async function getUpcomingDraws() {
  const [rows] = await pool.execute(
    `SELECT d.*, l.name as game_name, l.prize 
     FROM draws d 
     JOIN lotteries l ON d.lottery_id = l.id
     WHERE d.deleted_at IS NULL 
     ORDER BY d.draw_date ASC`
  );
  return rows;
}

async function getDrawResults() {
  const [rows] = await pool.execute(
    `SELECT d.*, l.name as game_name, l.prize 
     FROM draws d 
     JOIN lotteries l ON d.lottery_id = l.id
     WHERE d.status = 'completed' AND d.deleted_at IS NULL 
     ORDER BY d.draw_date DESC LIMIT 10`
  );
  return rows;
}

async function getDrawById(id) {
  const [rows] = await pool.execute(
    `SELECT d.*, l.name as game_name, l.prize, l.start_range, l.end_range, l.number_of_selection, l.type_of_game
     FROM draws d 
     JOIN lotteries l ON d.lottery_id = l.id
     WHERE d.id = ? AND d.deleted_at IS NULL LIMIT 1`,
    [id]
  );
  return rows.length ? rows[0] : null;
}

async function updateDrawResult(id, winning_numbers, status = 'completed') {
  const [result] = await pool.execute(
    `UPDATE draws SET winning_numbers = ?, status = ?, updated_at = NOW() WHERE id = ?`,
    [JSON.stringify(winning_numbers), status, id]
  );
  return result.affectedRows > 0;
}

async function updateDraw(id, { name, draw_date, cutoff_date, lottery_id, updated_by }) {
  const [result] = await pool.execute(
    `UPDATE draws 
     SET name = ?, draw_date = ?, cutoff_date = ?, lottery_id = ?, updated_by = ?, updated_at = NOW() 
     WHERE id = ?`,
    [name, draw_date, cutoff_date, lottery_id, updated_by, id]
  );
  return result.affectedRows > 0;
}

module.exports = {
  createDraw,
  getUpcomingDraws,
  getDrawById,
  updateDrawResult,
  getDrawResults,
  updateDraw
};
