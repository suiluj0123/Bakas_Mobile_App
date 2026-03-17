const pool = require('../../db');

async function findOperatorByUsername(username) {
  const [rows] = await pool.execute(
    `SELECT * FROM operators WHERE user_name = ? AND deleted_at IS NULL LIMIT 1`,
    [username]
  );
  return rows.length ? rows[0] : null;
}

async function createOperator({ role_id, first_name, last_name, middle_name, user_name, password, mobile_num, email, created_by }) {
  const [result] = await pool.execute(
    `INSERT INTO operators 
      (role_id, first_name, last_name, middle_name, user_name, password, mobile_num, email, created_by, updated_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
    [role_id, first_name, last_name, middle_name, user_name, password, mobile_num, email, created_by, created_by]
  );
  return { id: result.insertId };
}

async function findOperatorByEmail(email) {
  const [rows] = await pool.execute(
    `SELECT * FROM operators WHERE email = ? AND deleted_at IS NULL LIMIT 1`,
    [email]
  );
  return rows.length ? rows[0] : null;
}

module.exports = {
  findOperatorByUsername,
  findOperatorByEmail,
  createOperator
};
