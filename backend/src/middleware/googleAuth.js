const { OAuth2Client } = require('google-auth-library');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);


async function verifyGoogleToken(req, res, next) {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        ok: false,
        message: 'Google ID token is required.',
      });
    }

    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();

    req.googleUser = {
      googleId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified,
      name: payload.name,
      givenName: payload.given_name,
      familyName: payload.family_name,
      picture: payload.picture,
    };

    next();
  } catch (error) {
    console.error('Google token verification failed:', error);
    return res.status(401).json({
      ok: false,
      message: 'Invalid Google token.',
    });
  }
}

module.exports = { verifyGoogleToken };
