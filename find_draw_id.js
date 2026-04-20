const pool = require('./backend/db');
(async () => {
  try {
    const [rows] = await pool.execute('SELECT id FROM draws WHERE deleted_at IS NULL ORDER BY id DESC LIMIT 1');
    console.log('Valid Draw ID:', rows[0] ? rows[0].id : 'None found');
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
})();
