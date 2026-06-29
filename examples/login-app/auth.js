// Minimal auth module for gstack-ghcp workflow demo.

/**
 * Validate an email/password pair against an in-memory user store.
 * @param {{email:string,password:string}} user
 * @param {string} email
 * @param {string} password
 * @returns {boolean}
 */
function login(user, email, password) {
  if (!email || !password) return false;
  return user.email === email && user.password === password;
}

module.exports = { login };
