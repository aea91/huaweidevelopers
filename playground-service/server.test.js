'use strict';

const { after, before, test } = require('node:test');
const assert = require('node:assert/strict');
const { server } = require('./server');

let baseUrl;

before(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test('health endpoint reports ready', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok', activeRuns: 0 });
});

test('run endpoint rejects empty code', async () => {
  const response = await fetch(`${baseUrl}/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code: '   ' }),
  });

  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), { error: 'code is required.' });
});

test('run endpoint rejects invalid JSON', async () => {
  const response = await fetch(`${baseUrl}/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{',
  });

  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), {
    error: 'Request body must be valid JSON.',
  });
});

test('run endpoint rejects code that fails the ArkTS check', async () => {
  const response = await fetch(`${baseUrl}/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code: 'let a: any = 1\nprint(a)' }),
  });

  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.success, false);
  assert.equal(body.stage, 'check');
  assert.equal(body.compileExitCode, 1);
  assert.equal(body.runtimeExitCode, null);
  assert.match(body.compileOutput, /arkts-no-any-unknown/);
  assert.equal(body.diagnostics[0].code, 'arkts-no-any-unknown');
});
