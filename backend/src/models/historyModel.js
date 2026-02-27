const pool = require('../../db');

/**
 * @param {number} playerId 
 * @returns {Promise<Array>}
 */
async function getHistoryByPlayerId(playerId) {
  const [rows] = await pool.execute(
    `SELECT 
      id, 
      player_id, 
      transaction_code, 
      type, 
      channel, 
      amount, 
      status, 
      balance, 
      created_by, 
      updated_by, 
      created_at, 
      updated_at, 
      deleted_at 
    FROM histories 
    WHERE player_id = ? 
    ORDER BY created_at DESC`,
    [playerId]
  );
  return rows;
}

/**
 * 
 * @param {string} transactionCode 
 * @returns {Promise<Object|null>}
 */
async function getHistoryByCode(transactionCode) {
  const [rows] = await pool.execute(
    `SELECT 
      id, 
      player_id, 
      transaction_code, 
      type, 
      channel, 
      amount, 
      status, 
      balance, 
      created_by, 
      updated_by, 
      created_at, 
      updated_at, 
      deleted_at 
    FROM histories 
    WHERE transaction_code = ? 
    LIMIT 1`,
    [transactionCode]
  );
  if (!rows || rows.length === 0) return null;
  return rows[0];
}

module.exports = {
  getHistoryByPlayerId,
  getHistoryByCode,
};
