const pool = require('../../db');

/**
 * 
 * @param {number} playerId 
 * @returns {Promise<Array>}
 */
async function getMessagesByPlayerId(playerId) {
  const [rows] = await pool.execute(
    `SELECT 
      id, 
      player_id, 
      message, 
      \`all\`, 
      \`read\`, 
      created_by, 
      updated_by, 
      created_at, 
      updated_at, 
      deleted_at 
    FROM message_centers 
    WHERE (player_id = ? OR \`all\` = 1) AND deleted_at IS NULL
    ORDER BY created_at DESC`,
    [playerId]
  );
  return rows;
}

/**
 * 
 * @param {number} id 
 * @returns {Promise<boolean>}
 */
async function markMessageAsRead(id) {
  const [result] = await pool.execute(
    'UPDATE message_centers SET `read` = 1, updated_at = NOW() WHERE id = ?',
    [id]
  );
  return result.affectedRows > 0;
}

/**
 *
 * @param {number} id 
 * @returns {Promise<boolean>}
 */
async function deleteMessage(id) {
  const [result] = await pool.execute(
    'UPDATE message_centers SET deleted_at = NOW() WHERE id = ?',
    [id]
  );
  return result.affectedRows > 0;
}

module.exports = {
  getMessagesByPlayerId,
  markMessageAsRead,
  deleteMessage,
};
