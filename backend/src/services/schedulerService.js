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

        const startRange = draw.start_range || 1;
        const endRange = draw.end_range || 42;
        const count = draw.number_of_selection || 6;

        const winningNumbers = [];
        while (winningNumbers.length < count) {
          const num = Math.floor(Math.random() * (endRange - startRange + 1)) + startRange;
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

function startScheduler() {
  setInterval(checkAndProcessDraws, 60000);
  checkAndProcessDraws(); 
}

module.exports = { startScheduler };
