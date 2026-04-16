const pool = require('../../db');
const messageCenterModel = require('../models/messageCenterModel');
const notificationModel = require('../models/notificationModel');

async function processDraw(drawId, winningNumbers) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    await connection.execute(
      `UPDATE draws SET status = 'completed', winning_numbers = ?, updated_at = NOW() WHERE id = ?`,
      [winningNumbers.join(','), drawId]
    );

    // Broadcast results notification
    // Fetch draw name first if needed, or just use a generic message
    // To be precise, I'll fetch the draw name
    const [[drawInfo]] = await connection.execute(
      'SELECT name FROM draws WHERE id = ?',
      [drawId]
    );
    
    await notificationModel.broadcastNotification(
      'Draw Results Available!',
      `The results for ${drawInfo ? drawInfo.name : 'the recent draw'} are now available. Check your tickets!`,
      'result'
    );

    const [bets] = await connection.execute(
      `SELECT b.*, p.first_name, p.last_name 
       FROM bets b
       JOIN players p ON b.player_id = p.id
       WHERE b.drawdate_id = ? AND b.status = 'pending'`,
      [drawId]
    );

    for (const bet of bets) {
      const playerNumbers = bet.selected_numbers ? JSON.parse(bet.selected_numbers) : [];
      const winningArray = winningNumbers;

      const matches = playerNumbers.filter(n => winningArray.includes(n)).length;
      
      let status = 'lost';
      let winAmount = 0;

      if (matches === 6) {
        status = 'won';
        winAmount = 1000000;
      } else if (matches === 5) {
        status = 'won';
        winAmount = 50000;
      } else if (matches === 4) {
        status = 'won';
        winAmount = 2000;
      } else if (matches === 3) {
        status = 'won';
        winAmount = 100;
      }

      if (status === 'won') {
        await connection.execute(
          `UPDATE bets SET status = 'won', winning_amount = ?, updated_at = NOW() WHERE id = ?`,
          [winAmount, bet.id]
        );

        await connection.execute(
          `UPDATE players SET credit = credit + ? WHERE id = ?`,
          [winAmount, bet.player_id]
        );

        const transactionCode = `WIN-${Date.now()}-${bet.id}`;
        const [updatedPlayer] = await connection.execute(
          'SELECT credit FROM players WHERE id = ?',
          [bet.player_id]
        );
        const newBalance = updatedPlayer[0].credit;

        await connection.execute(
          `INSERT INTO histories 
           (player_id, transaction_code, type, channel, amount, status, balance, created_at, updated_at) 
           VALUES (?, ?, 'LOTTERY_WIN', 'WALLET', ?, 1, ?, NOW(), NOW())`,
          [bet.player_id, transactionCode, winAmount, newBalance]
        );

        await messageCenterModel.createMessage({
          senderId: 0, // System
          receiverId: bet.player_id,
          subject: '🎉 Congratulations! You are a Winner!',
          content: `You unmatched luck! Your ticket for **${bet.lottery_name || 'Bakas'}** matched ${matches} numbers. 
          
₱ ${winAmount.toLocaleString()} has been credited to your wallet. 
          
Keep playing and good luck!`
        });
      } else {
        await connection.execute(
          `UPDATE bets SET status = 'lost', updated_at = NOW() WHERE id = ?`,
          [bet.id]
        );
      }
    }

    await connection.commit();
    return { success: true };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

module.exports = {
  processDraw
};
