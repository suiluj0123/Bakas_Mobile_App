const drawModel = require('../models/drawModel');
const lotteryService = require('./lotteryService');
const { getPHTime } = require('../utils/timeUtils');

async function checkAndProcessDraws() {
  try {
    const draws = await drawModel.getUpcomingDraws();
    const now = getPHTime();

    for (const draw of draws) {
      const drawDate = new Date(draw.draw_date);
      if (drawDate <= now && draw.status !== 'completed') {
 
        const winningNumbers = [];
        while (winningNumbers.length < 6) {
          const num = Math.floor(Math.random() * 42) + 1;
          if (!winningNumbers.includes(num)) winningNumbers.push(num);
        }
        winningNumbers.sort((a, b) => a - b);

        await lotteryService.processDraw(draw.id, winningNumbers);

      }
    }
  } catch (error) {
    console.error('Error in checkAndProcessDraws:', error);
  }
}

// Run every minute
function startScheduler() {
  setInterval(checkAndProcessDraws, 60000);
  checkAndProcessDraws(); // Run initially
}

module.exports = { startScheduler };
