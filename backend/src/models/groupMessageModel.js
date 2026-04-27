const pool = require('../../db');

/**
 *
 * @param {number} groupId 
 * @param {number} limit 
 * @returns {Promise<Array>}
 */
async function getGroupMessages(groupId, limit = 50) {

  const [rows] = await pool.query(
    `SELECT 
      gm.id, 
      gm.group_id, 
      gm.sender_id, 
      gm.message, 
      gm.created_at,
      COALESCE(CONCAT(p.first_name, ' ', p.last_name), 'Unknown Player') as sender_name
    FROM group_messages gm
    LEFT JOIN players p ON gm.sender_id = p.id
    WHERE gm.group_id = ?
    ORDER BY gm.created_at ASC
    LIMIT ?`,
    [parseInt(groupId), parseInt(limit)]
  );
  return rows;
}



/**
 * 
 * @param {Object} data 
 * @returns {Promise<Object>}
 */
async function createGroupMessage({ groupId, senderId, message }) {
  const [result] = await pool.execute(
    `INSERT INTO group_messages (group_id, sender_id, message, created_at)
     VALUES (?, ?, ?, NOW())`,
    [groupId, senderId, message]
  );
  return { id: result.insertId };
}

module.exports = {
  getGroupMessages,
  createGroupMessage,
};
