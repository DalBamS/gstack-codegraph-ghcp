const assert = require('assert');
const { authenticate, rateLimit } = require('./service');

const u = { email: 'a@b.com', password: 'pw' };
assert.strictEqual(authenticate(u, 'a@b.com', 'pw', 1), 'ok');
assert.strictEqual(authenticate(u, 'a@b.com', 'bad', 1), 'denied');
assert.strictEqual(authenticate(u, 'a@b.com', 'pw', 9), 'locked');
assert.strictEqual(rateLimit(5), true);
assert.strictEqual(rateLimit(6), false);
console.log('service tests passed');
