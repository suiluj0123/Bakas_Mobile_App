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

module.exports = {
  findUserByEmail,
  findPlayerByNameAndBirthdate,
  findPlayerByEmail,
  createPlayer,
  findPlayerByGoogleId,
  createGooglePlayer,
};