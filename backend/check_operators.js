const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkOperators() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
  });

  try {
    const [rows] = await connection.execute('SELECT * FROM operators');
    console.log('Existing Operators:');
    console.table(rows);
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await connection.end();
  }
}

checkOperators();
