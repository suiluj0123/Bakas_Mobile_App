const pool = require('../../db');

async function createNotification(user_id, title, message, type = 'general') {
  const [result] = await pool.execute(
    `INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
     VALUES (?, ?, ?, ?, FALSE, UTC_TIMESTAMP())`,
    [user_id, title, message, type]
  );
  return result.insertId;
}

/**
 *
 */
async function broadcastNotification(title, message, type = 'general') {
  // Using INSERT INTO ... SELECT to efficiently create notifications for all players
  const [result] = await pool.execute(
    `INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
     SELECT id, ?, ?, ?, FALSE, UTC_TIMESTAMP() FROM players WHERE deleted_at IS NULL`,
    [title, message, type]
  );
  return result.affectedRows;
}

async function getNotificationsByUserId(user_id) {
  const [rows] = await pool.execute(
    `SELECT * FROM notifications 
     WHERE user_id = ? 
     ORDER BY created_at DESC 
     LIMIT 50`,
    [user_id]
  );
  return rows;
}

async function getUnreadCount(user_id) {
  const [rows] = await pool.execute(
    `SELECT COUNT(*) as count FROM notifications 
     WHERE user_id = ? AND is_read = FALSE`,
    [user_id]
  );
  return rows[0].count;
}

async function markAsRead(id) {
  const [result] = await pool.execute(
    `UPDATE notifications SET is_read = TRUE WHERE id = ?`,
    [id]
  );
  return result.affectedRows > 0;
}

async function markAllAsRead(user_id) {
  const [result] = await pool.execute(
    `UPDATE notifications SET is_read = TRUE WHERE user_id = ?`,
    [user_id]
  );
  return result.affectedRows;
}

/**
 * Logic for Ongoing Game notifications:
 * Finds games closing in 30-60 mins that haven't had an 'ongoing' notification yet.
 * This is a simplified version; in a real app, you'd likely track which notifications have been sent.
 */
async function getImpendingCutoffs() {
  const [rows] = await pool.execute(
    `SELECT d.*, l.name as game_name 
     FROM draws d
     JOIN lotteries l ON d.lottery_id = l.id
     WHERE d.status = 'upcoming' 
     AND d.cutoff_date <= DATE_ADD(NOW(), INTERVAL 1 HOUR)
     AND d.cutoff_date > NOW()
     AND d.deleted_at IS NULL`
  );
  return rows;
}

async function deleteNotification(id) {
  const [result] = await pool.execute(
    `DELETE FROM notifications WHERE id = ?`,
    [id]
  );
  return result.affectedRows > 0;
}

async function deleteAllNotifications(user_id) {
  const [result] = await pool.execute(
    `DELETE FROM notifications WHERE user_id = ?`,
    [user_id]
  );
  return result.affectedRows;
}

module.exports = {
  createNotification,
  broadcastNotification,
  getNotificationsByUserId,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  getImpendingCutoffs,
  deleteNotification,
  deleteAllNotifications,
};
