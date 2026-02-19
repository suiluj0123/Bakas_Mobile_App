const bcrypt = require('bcryptjs');
const {
  findUserByEmail,
  findPlayerByNameAndBirthdate,
  findPlayerByEmail,
  createPlayer,
} = require('../models/userModel');

async function login(req, res, next) {
  try {
    const { email, password } = req.body ?? {};

    if (typeof email !== 'string' || typeof password !== 'string') {
      return res
        .status(400)
        .json({ ok: false, message: 'Email and password are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) {
      return res
        .status(400)
        .json({ ok: false, message: 'Email is required.' });
    }
    if (!password) {
      return res
        .status(400)
        .json({ ok: false, message: 'Password is required.' });
    }

    // Check players table first (where registration creates accounts)
    let user = await findPlayerByEmail(normalizedEmail);
    let source = 'players';

    // If not found in players, check users table (for backward compatibility)
    if (!user) {
      user = await findUserByEmail(normalizedEmail);
      source = 'users';
    }

    if (!user) {
      console.warn(`[LOGIN] Untrusted attempt: ${normalizedEmail} not found in any table.`);
      return res
        .status(401)
        .json({ ok: false, message: 'Invalid credentials.' });
    }

    console.log(`[LOGIN] User ${normalizedEmail} found in [${source}] table with ID: ${user.id}`);

    const matches = await bcrypt.compare(password, user.password);
    if (!matches) {
      return res
        .status(401)
        .json({ ok: false, message: 'Invalid credentials.' });
    }

    // Extract first_name - for players table it exists, for users table extract from name
    let firstName = user.first_name;
    if (!firstName && user.name) {
      // If from users table, extract first name from name field
      firstName = user.name.split(' ')[0];
    }

    return res.status(200).json({
      ok: true,
      user: {
        id: user.id,
        name: user.name || `${user.first_name || ''} ${user.last_name || ''}`.trim(),
        first_name: firstName || null,
        last_name: user.last_name || null,
        email: user.email,
      },
    });
  } catch (err) {
    return next(err);
  }
}

// NEW: register a player into `players` table
async function register(req, res, next) {
  try {
    const {
      first_name: rawFirstName,
      last_name: rawLastName,
      email,
      birthdate,
      password,
    } = req.body ?? {};

    const firstName =
      typeof rawFirstName === 'string' ? rawFirstName.trim() : '';
    const lastName =
      typeof rawLastName === 'string' ? rawLastName.trim() : '';
    const rawEmail =
      typeof email === 'string' ? email.trim().toLowerCase() : '';
    const pwd = typeof password === 'string' ? password : '';

    if (!firstName || !lastName || !rawEmail || !birthdate || !pwd) {
      return res.status(400).json({
        ok: false,
        message:
          'First name, last name, email, birthdate and password are required.',
      });
    }

    if (!rawEmail.includes('@')) {
      return res
        .status(400)
        .json({ ok: false, message: 'A valid email is required.' });
    }

    if (pwd.length < 6) {
      return res.status(400).json({
        ok: false,
        message: 'Password must be at least 6 characters.',
      });
    }

    // Check duplicates by email
    const existingByEmail = await findPlayerByEmail(rawEmail);
    if (existingByEmail) {
      return res
        .status(400)
        .json({ ok: false, message: 'Email is already registered.' });
    }

    // Optional: also prevent duplicates by name + birthdate
    const existingByNameDob = await findPlayerByNameAndBirthdate(
      firstName,
      lastName,
      birthdate
    );
    if (existingByNameDob) {
      return res.status(400).json({
        ok: false,
        message: 'Player with same name and birthdate already exists.',
      });
    }

    const hashedPassword = await bcrypt.hash(pwd, 10);

    const result = await createPlayer({
      firstName,
      lastName,
      email: rawEmail,
      birthdate,
      password: hashedPassword,
    });

    return res.status(200).json({
      ok: true,
      message: 'Registration successful.',
      playerId: result.insertId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { login, register };