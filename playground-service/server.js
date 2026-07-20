'use strict';

const http = require('node:http');
const { spawn } = require('node:child_process');
const { mkdtemp, rm, writeFile } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const { join } = require('node:path');

const PORT = Number(process.env.PORT || 8080);
const COMPILER_PATH = process.env.ARK_COMPILER_PATH || '/opt/ark/bin/es2abc';
const RUNTIME_PATH = process.env.ARK_RUNTIME_PATH || '/opt/ark/bin/ark_js_vm';
const MAX_SOURCE_BYTES = Number(process.env.MAX_SOURCE_BYTES || 64 * 1024);
const PROCESS_TIMEOUT_MS = Number(process.env.PROCESS_TIMEOUT_MS || 5000);
const MAX_CONCURRENT_RUNS = Number(process.env.MAX_CONCURRENT_RUNS || 2);
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || '*';

let activeRuns = 0;

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  res.end(JSON.stringify(payload));
}

async function readJsonBody(req) {
  const chunks = [];
  let size = 0;

  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_SOURCE_BYTES + 1024) {
      throw Object.assign(new Error('Request body is too large.'), { statusCode: 413 });
    }
    chunks.push(chunk);
  }

  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch (_) {
    throw Object.assign(new Error('Request body must be valid JSON.'), { statusCode: 400 });
  }
}

function runProcess(command, args, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      env: {
        LANG: 'C.UTF-8',
        LD_LIBRARY_PATH: process.env.ARK_LIBRARY_PATH || '/opt/ark/lib',
        PATH: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      },
      detached: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';
    let settled = false;

    const append = (current, chunk) => {
      const next = current + chunk.toString('utf8');
      return next.length > 128 * 1024 ? next.slice(0, 128 * 1024) : next;
    };

    child.stdout.on('data', (chunk) => {
      stdout = append(stdout, chunk);
    });
    child.stderr.on('data', (chunk) => {
      stderr = append(stderr, chunk);
    });

    const timer = setTimeout(() => {
      if (settled) return;
      settled = true;
      try {
        process.kill(-child.pid, 'SIGKILL');
      } catch (_) {
        child.kill('SIGKILL');
      }
      resolve({
        exitCode: 124,
        output: `${stdout}${stderr}\nExecution timed out after ${PROCESS_TIMEOUT_MS} ms.`.trim(),
      });
    }, PROCESS_TIMEOUT_MS);

    child.on('error', (error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      reject(error);
    });

    child.on('close', (exitCode) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolve({
        exitCode: exitCode ?? 1,
        output: `${stdout}${stderr}`.trim(),
      });
    });
  });
}

async function compileAndRun(code) {
  const startedAt = Date.now();
  const workDirectory = await mkdtemp(join(tmpdir(), 'arkts-'));
  const sourcePath = join(workDirectory, 'main.ts');
  const bytecodePath = join(workDirectory, 'main.abc');

  try {
    await writeFile(sourcePath, code, { encoding: 'utf8', mode: 0o600 });

    const compile = await runProcess(
      COMPILER_PATH,
      ['--extension=ts', '--output', bytecodePath, sourcePath],
      workDirectory,
    );

    if (compile.exitCode !== 0) {
      return {
        success: false,
        compileOutput: compile.output,
        runtimeOutput: '',
        compileExitCode: compile.exitCode,
        runtimeExitCode: null,
        durationMs: Date.now() - startedAt,
      };
    }

    const runtime = await runProcess(RUNTIME_PATH, [bytecodePath], workDirectory);
    return {
      success: runtime.exitCode === 0,
      compileOutput: compile.output,
      runtimeOutput: runtime.output,
      compileExitCode: compile.exitCode,
      runtimeExitCode: runtime.exitCode,
      durationMs: Date.now() - startedAt,
    };
  } finally {
    await rm(workDirectory, { recursive: true, force: true });
  }
}

async function handleRun(req, res) {
  if (activeRuns >= MAX_CONCURRENT_RUNS) {
    sendJson(res, 429, { error: 'Playground is busy. Please try again shortly.' });
    return;
  }

  const body = await readJsonBody(req);
  const code = typeof body.code === 'string' ? body.code : '';
  const sourceSize = Buffer.byteLength(code, 'utf8');

  if (!code.trim()) {
    sendJson(res, 400, { error: 'code is required.' });
    return;
  }
  if (sourceSize > MAX_SOURCE_BYTES) {
    sendJson(res, 413, { error: `code must not exceed ${MAX_SOURCE_BYTES} bytes.` });
    return;
  }

  activeRuns += 1;
  try {
    sendJson(res, 200, await compileAndRun(code));
  } finally {
    activeRuns -= 1;
  }
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    sendJson(res, 204, {});
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    sendJson(res, 200, { status: 'ok', activeRuns });
    return;
  }

  if (req.method === 'POST' && req.url === '/run') {
    try {
      await handleRun(req, res);
    } catch (error) {
      console.error('Run failed:', error);
      sendJson(res, error.statusCode || 500, {
        error: error.code === 'ENOENT'
          ? 'ArkCompiler toolchain is not installed in the container.'
          : error.message || 'Compilation failed.',
      });
    }
    return;
  }

  sendJson(res, 404, { error: 'Not Found' });
});

if (require.main === module) {
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`ArkTS playground service listening on ${PORT}`);
  });
}

module.exports = { compileAndRun, readJsonBody, server };
