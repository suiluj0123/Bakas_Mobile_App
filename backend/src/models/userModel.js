const pool = require('../../db');

async function findUserByEmail(email) {
  const [rows] = await pool.execute(
    'SELECT id, name, email, password FROM users WHERE email = ? LIMIT 1',
    [email]
  );

  if (!rows || rows.length === 0) return null;
  return rows[0];
}

async function findPlayerByNameAndBirthdate(firstName, lastName, birthdate) {
  const [rows] = await pool.execute(
    'SELECT id, first_name, last_name, birthdate FROM players WHERE first_name = ? AND last_name = ? AND birthdate = ? LIMIT 1',
    [firstName, lastName, birthdate]
  );

  if (!rows || rows.length === 0) return null;
  return rows[0];
}

async function findPlayerByEmail(email) {
  const [rows] = await pool.execute(
    'SELECT id, first_name, last_name, email, birthdate, password FROM players WHERE email = ? LIMIT 1',
    [email]
  );

  if (!rows || rows.length === 0) return null;
  return rows[0];
}

async function createPlayer({ firstName, lastName, email, birthdate, password }) {

  const code = `PLR-${Date.now()}`;

  const credit = 0.00;
  const cashInLimit = 300000.00;
  const empty = '';

  const [result] = await pool.execute(
    `INSERT INTO players
      (code,
       credit,
       cash_in_limit,
       first_name,
       last_name,
       middle_name,
       password,
       birthdate,
       contact_num,
       address,
       region_code,
       provincial_code,
       city_code,
       barangay_code,
       id_code,
       id_number,
       id_photo,
       email,
       picture,
       status,
       login_status,
       created_by,
       updated_by,
       created_at,
       updated_at,
       deleted_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NULL)`,
    [
      code,
      credit,
      cashInLimit,
      firstName,
      lastName,
      empty,
      password,
      birthdate,
      null,
      empty,
      null,
      null,
      null,
      null,
      empty,
      null,
      empty,
      email,
      empty,
      1,
      0,
      empty,
      empty,
    ]
  );

  return result;
}

async function findPlayerByGoogleId(googleId) {
  const [rows] = await pool.execute(
    'SELECT id, first_name, last_name, email, google_id, birthdate FROM players WHERE google_id = ? LIMIT 1',
    [googleId]
  );

  if (!rows || rows.length === 0) return null;
  return rows[0];
}

async function createGooglePlayer({ googleId, email, firstName, lastName }) {
  const code = `PLR-${Date.now()}`;
  const credit = 0.00;
  const cashInLimit = 300000.00;
  const empty = '';

  const [result] = await pool.execute(
    `INSERT INTO players
      (code,
       credit,
       cash_in_limit,
       first_name,
       last_name,
       middle_name,
       password,
       birthdate,
       contact_num,
       address,
       region_code,
       provincial_code,
       city_code,
       barangay_code,
       id_code,
       id_number,
       id_photo,
       email,
       google_id,
       picture,
       status,
       login_status,
       created_by,
       updated_by,
       created_at,
       updated_at,
       deleted_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NULL)`,
    [
      code,
      credit,
      cashInLimit,
      firstName,
      lastName,
      empty,
      null,
      null,
      null,
      empty,
      null,
      null,
      null,
      null,
      empty,
      null,
      empty,
      email,
      googleId,
      empty,
      1,
      0,
      empty,
      empty,
    ]
  );

  return result;
}

async function savePasswordResetToken(email, token) {
  // First, delete any existing tokens for this email to avoid duplicates
  await pool.execute('DELETE FROM password_resets WHERE email = ?', [email]);

  const [result] = await pool.execute(
    'INSERT INTO password_resets (email, token, created_at) VALUES (?, ?, NOW())',
    [email, token]
  );
  return result;
}

async function findResetToken(email, token) {
  const [rows] = await pool.execute(
    'SELECT email, token, created_at FROM password_resets WHERE email = ? AND token = ? LIMIT 1',
    [email, token]
  );
  if (!rows || rows.length === 0) return null;
  return rows[0];
}

async function deleteResetToken(email) {
  const [result] = await pool.execute(
    'DELETE FROM password_resets WHERE email = ?',
    [email]
  );
  return result;
}

async function updatePlayerPassword(email, hashedPassword) {
  // Update in players table
  const [resultPlayers] = await pool.execute(
    'UPDATE players SET password = ?, updated_at = NOW() WHERE email = ?',
    [hashedPassword, email]
  );

  // Also update in users table if exists (for compatibility)
  await pool.execute(
    'UPDATE users SET password = ? WHERE email = ?',
    [hashedPassword, email]
  );

  return resultPlayers;
}

module.exports = {
  findUserByEmail,
  findPlayerByNameAndBirthdate,
  findPlayerByEmail,
  createPlayer,
  findPlayerByGoogleId,
  createGooglePlayer,
  savePasswordResetToken,
  findResetToken,
  deleteResetToken,
  updatePlayerPassword,
};