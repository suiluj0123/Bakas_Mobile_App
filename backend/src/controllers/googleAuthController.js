const {
  findPlayerByGoogleId,
  findPlayerByEmail,
  createGooglePlayer,
} = require('../models/userModel');


async function googleLogin(req, res, next) {
  try {
    const { googleId, email, givenName, familyName, name } = req.googleUser;

    let user = await findPlayerByGoogleId(googleId);

    if (!user) {
      user = await findPlayerByEmail(email);

      if (user && !user.google_id) {
        return res.status(409).json({
          ok: false,
          message: 'An account with this email already exists. Please login with email/password.',
        });
      }
    }

    if (!user) {
      const firstName = givenName || name?.split(' ')[0] || 'User';
      const lastName = familyName || name?.split(' ').slice(1).join(' ') || '';

      const result = await createGooglePlayer({
        googleId,
        email,
        firstName,
        lastName,
      });

      user = await findPlayerByGoogleId(googleId);
    }

    return res.status(200).json({
      ok: true,
      user: {
        name: `${user.first_name || ''} ${user.last_name || ''}`.trim() || user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
      },
    });
  } catch (err) {
    console.error('Google login error:', err);
    return next(err);
  }
}

module.exports = { googleLogin };
