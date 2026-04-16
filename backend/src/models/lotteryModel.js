const pool = require('../../db');

async function createLottery({ name, prize, start_range, end_range, number_of_selection, type_of_game, initial, remarks, created_by }) {
  const [result] = await pool.execute(
    `INSERT INTO lotteries 
      (name, prize, start_range, end_range, number_of_selection, type_of_game, initial, remarks, created_by, updated_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
    [name, prize, start_range, end_range, number_of_selection, type_of_game, initial, remarks, created_by, created_by]
  );
  return { id: result.insertId };
}

async function getAllLotteries() {
  const [rows] = await pool.execute(
    `SELECT * FROM lotteries WHERE deleted_at IS NULL ORDER BY name ASC`
  );
  return rows;
}

async function getLotteryById(id) {
  const [rows] = await pool.execute(
    `SELECT * FROM lotteries WHERE id = ? AND deleted_at IS NULL LIMIT 1`,
    [id]
  );
  return rows.length ? rows[0] : null;
}

async function updateLottery(id, { name, prize, start_range, end_range, number_of_selection, type_of_game, initial, remarks, updated_by }) {
  const [result] = await pool.execute(
    `UPDATE lotteries 
     SET name = ?, prize = ?, start_range = ?, end_range = ?, number_of_selection = ?, type_of_game = ?, initial = ?, remarks = ?, updated_by = ?, updated_at = NOW() 
     WHERE id = ?`,
    [name, prize, start_range, end_range, number_of_selection, type_of_game || 1, initial || 0, remarks || '', updated_by, id]
  );
  return result.affectedRows > 0;
}

async function deleteLottery(id) {
  const [result] = await pool.execute(
    `UPDATE lotteries SET deleted_at = NOW(), updated_at = NOW() WHERE id = ?`,
    [id]
  );
  return result.affectedRows > 0;
}

module.exports = {
  createLottery,
  getAllLotteries,
  getLotteryById,
  updateLottery,
  deleteLottery
};
