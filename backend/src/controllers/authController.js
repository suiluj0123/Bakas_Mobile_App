const bcrypt = require('bcryptjs');
const {
  findUserByEmail,
  findPlayerByNameAndBirthdate,
  findPlayerByEmail,
  createPlayer,
  savePasswordResetToken,
  findResetToken,
  deleteResetToken,
  updatePlayerPassword,
} = require('../models/userModel');
const { findOperatorByEmail } = require('../models/operatorModel');

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

    let user = await findPlayerByEmail(normalizedEmail);
    let source = 'players';
    let roleId = 1; 

    if (!user) {
      user = await findOperatorByEmail(normalizedEmail);
      if (user) {
        source = 'operators';
        roleId = user.role_id || 2;
      }
    }

    if (!user) {
      user = await findUserByEmail(normalizedEmail);
      if (user) {
        source = 'users';
        roleId = 1;
      }
    }

    if (!user) {
      console.warn(`[LOGIN] Untrusted attempt: ${normalizedEmail} not found in any table.`);
      return res
        .status(401)
        .json({ ok: false, message: 'Invalid credentials.' });
    }

    let matches = false;
    if (user.password && user.password.startsWith('$2')) {
        matches = await bcrypt.compare(password, user.password);
    } else {
        matches = (password === user.password);
    }

    if (!matches) {
      return res
        .status(401)
        .json({ ok: false, message: 'Invalid credentials.' });
    }

    let firstName = user.first_name;
    if (!firstName && user.name) {
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
        role_id: roleId,
      },
    });
  } catch (err) {
    return next(err);
  }
}

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

    const existingByEmail = await findPlayerByEmail(rawEmail);
    if (existingByEmail) {
      return res
        .status(400)
        .json({ ok: false, message: 'Email is already registered.' });
    }

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

async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body ?? {};
    if (!email) {
      return res.status(400).json({ ok: false, message: 'Email is required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    let user = await findPlayerByEmail(normalizedEmail);
    if (!user) {
      user = await findUserByEmail(normalizedEmail);
    }

    if (!user) {
      return res.status(404).json({ ok: false, message: 'Email not found.' });
    }

    const token = Math.floor(100000 + Math.random() * 900000).toString();

    await savePasswordResetToken(normalizedEmail, token);

    console.log(`[FORGOT PASSWORD] Generated token for ${normalizedEmail}: ${token}`);

    return res.status(200).json({
      ok: true,
      message: 'Password reset token generated.',
      token: token
    });
  } catch (err) {
    return next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { email, token, newPassword } = req.body ?? {};
    if (!email || !token || !newPassword) {
      return res.status(400).json({ ok: false, message: 'Email, token, and new password are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const resetEntry = await findResetToken(normalizedEmail, token);
    if (!resetEntry) {
      return res.status(400).json({ ok: false, message: 'Invalid or expired token.' });
    }

    const createdAt = new Date(resetEntry.created_at);
    const now = new Date();
    const diffHours = (now - createdAt) / (1000 * 60 * 60);
    if (diffHours > 1) {
      await deleteResetToken(normalizedEmail);
      return res.status(400).json({ ok: false, message: 'Token has expired.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ ok: false, message: 'Password must be at least 6 characters.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await updatePlayerPassword(normalizedEmail, hashedPassword);

    await deleteResetToken(normalizedEmail);

    return res.status(200).json({
      ok: true,
      message: 'Password has been reset successfully.'
    });
  } catch (err) {
    return next(err);
  }
}

async function searchPlayers(req, res) {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(200).json({ ok: true, data: [] });
    }
    const { searchPlayers: searchModel } = require('../models/userModel');
    const players = await searchModel(q);
    res.status(200).json({ ok: true, data: players });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = { login, register, forgotPassword, resetPassword, searchPlayers };