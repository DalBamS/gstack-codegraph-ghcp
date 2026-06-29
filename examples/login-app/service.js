const { login } = require('./auth');

function rateLimit(attempts) {
  return attempts <= 5;
}

function authenticate(user, email, password, attempts) {
  if (!rateLimit(attempts)) return 'locked';
  return login(user, email, password) ? 'ok' : 'denied';
}

module.exports = { authenticate, rateLimit };
