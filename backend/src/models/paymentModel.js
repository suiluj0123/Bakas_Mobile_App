const pool = require('../../db');

async function getPlayerWalletStats(playerId) {
  const [rows] = await pool.execute(
    'SELECT credit, cash_in_limit FROM players WHERE id = ? LIMIT 1',
    [playerId]
  );
  if (!rows || rows.length === 0) return null;
  return rows[0];
}

async function createTransaction({ playerId, type, amount, fee, paymentMethod, provider, status = 1 }) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [[player]] = await connection.execute(
      'SELECT credit, cash_in_limit FROM players WHERE id = ? FOR UPDATE',
      [playerId]
    );

    if (!player) throw new Error('Player not found');

    const currentCredit = Number(player.credit || 0);
    const currentLimit = Number(player.cash_in_limit || 0);

    const adjustment = type === 'CASH_IN' ? amount : -amount;
    const newBalance = currentCredit + adjustment;
    const transactionCode = `TXN-${Date.now()}`;

    const [result] = await connection.execute(
      `INSERT INTO histories 
       (player_id, transaction_code, type, channel, amount, status, balance, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        playerId,
        transactionCode,
        type,
        provider || paymentMethod,
        amount,
        status, 
        newBalance
      ]
    );

    await connection.execute(
      'UPDATE players SET credit = ? WHERE id = ?',
      [newBalance, playerId]
    );

    if (type === 'CASH_IN') {
      const newLimit = currentLimit - amount;
      await connection.execute(
        'UPDATE players SET cash_in_limit = ? WHERE id = ?',
        [newLimit, playerId]
      );
    }

    await connection.commit();
    return result.insertId;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

module.exports = {
  getPlayerWalletStats,
  createTransaction,
};
