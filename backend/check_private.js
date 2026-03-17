const pool = require('./db');
async function checkPrivateGroupsSchema() {
  try {
    const [rows] = await pool.execute('DESC `private_groups`');
    console.log('SCHEMA:', JSON.stringify(rows));

    const [data] = await pool.execute('SELECT status FROM `private_groups` LIMIT 5');
    console.log('DATA:', JSON.stringify(data));
  } catch (err) {
    console.error('ERROR:', err.message);
  } finally {
    process.exit(0);
  }
}
checkPrivateGroupsSchema();
