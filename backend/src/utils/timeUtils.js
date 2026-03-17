

function getPHTime() {
  const now = new Date();
  const phOffset = 8 * 60 * 60 * 1000;
  return new Date(now.getTime() + (now.getTimezoneOffset() * 60000) + phOffset);
}

function formatPHDate(date) {
  const d = date instanceof Date ? date : new Date(date);
  return d.toLocaleString('en-PH', { timeZone: 'Asia/Manila' });
}

module.exports = {
  getPHTime,
  formatPHDate
};
