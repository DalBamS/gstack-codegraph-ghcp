// Browser mirror of auth.js + service.js logic for the Playwright MCP demo.
// Same rules as the Node modules so QA verifies one behavior across CLI and browser.

function login(user, email, password) {
  if (!email || !password) return false;
  return user.email === email && user.password === password;
}

function rateLimit(attempts) {
  return attempts <= 5;
}

function authenticate(user, email, password, attempts) {
  if (!rateLimit(attempts)) return 'locked';
  return login(user, email, password) ? 'ok' : 'denied';
}
