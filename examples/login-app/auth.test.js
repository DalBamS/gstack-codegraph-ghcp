const assert = require('assert');
const { login } = require('./auth');

const u = { email: 'a@b.com', password: 'pw' };
assert.strictEqual(login(u, 'a@b.com', 'pw'), true);
assert.strictEqual(login(u, 'a@b.com', 'bad'), false);
assert.strictEqual(login(u, '', ''), false);
console.log('auth tests passed');
