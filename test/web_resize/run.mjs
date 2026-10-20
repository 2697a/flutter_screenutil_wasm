// Node 20.10+: node --experimental-websocket test/web_resize/run.mjs <web build>
// Runs an isolated headless Chrome; it never attaches to the user's browser.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import fs from 'node:fs/promises';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';

const build = path.resolve(process.argv[2] ?? 'test/web_resize/fixture/build/web');
const chromePath = process.env.CHROME_BIN ?? (process.platform === 'darwin'
  ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  : 'google-chrome');
const profile = await fs.mkdtemp(path.join(os.tmpdir(), 'screenutil-resize-'));
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
const server = http.createServer(async (req, res) => {
  try {
    const pathname = new URL(req.url, 'http://localhost').pathname;
    const file = path.resolve(build, `.${pathname === '/' ? '/index.html' : pathname}`);
    if (!file.startsWith(`${build}${path.sep}`)) {
      res.writeHead(403).end();
      return;
    }
    const content = await fs.readFile(file);
    const ext = path.extname(file);
    res.setHeader('Content-Type', ext === '.wasm' ? 'application/wasm'
      : ['.js', '.mjs'].includes(ext) ? 'application/javascript'
      : ext === '.html' ? 'text/html' : 'application/octet-stream');
    res.setHeader('Cache-Control', 'no-store');
    res.end(content);
  } catch {
    res.writeHead(404).end();
  }
});

let chrome;
let ws;
let nextId = 0;
const pending = new Map();
let errors = [];
let caseId;
const failures = [];

async function waitFor(read, description, timeout = 15000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const result = await read();
    if (result) return result;
    await delay(50);
  }
  throw new Error(`Timed out: ${description}`);
}

function send(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++nextId;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`CDP timeout: ${method}`));
    }, 15000);
    pending.set(id, { resolve, reject, timer });
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function evaluate(expression) {
  const response = await send('Runtime.evaluate', { expression, returnByValue: true });
  if (response.exceptionDetails) throw new Error(response.exceptionDetails.text);
  return response.result.value;
}

async function resize(width, height) {
  await send('Emulation.setDeviceMetricsOverride', {
    width, height, deviceScaleFactor: 1, mobile: false,
  });
}

async function checkSize(width, height) {
  const snapshot = await waitFor(async () => {
    const state = await evaluate(`globalThis.screenUtilResizeSnapshot
      ? JSON.parse(screenUtilResizeSnapshot()) : null`);
    if (!state?.ready || state.caseId !== caseId) return null;
    assert.deepEqual(errors, [], 'uncaught browser exception during resize');
    // Inspect rendered dimensions and the Text widget's configured font size,
    // not just the updated ScreenUtil singleton.
    const close = (a, b) => Math.abs(a - b) < 0.001;
    return close(state.width, 100 * width / 1133)
      && close(state.height, 40 * height / 744)
      // 5.9.3 defaults to FontSizeResolvers.width, including with minTextAdapt.
      && close(state.fontSize, 16 * width / 1133)
      ? state : null;
  }, `rendered scale at ${width}x${height}`);
  assert.equal(snapshot.created, 1, 'resize must retain the leaf State');
  assert.equal(snapshot.disposed, 0, 'resize must not dispose the leaf State');
  const view = await evaluate(`(() => {
    const rect = document.querySelector('flutter-view').getBoundingClientRect();
    return {width: rect.width, height: rect.height};
  })()`);
  assert.deepEqual(view, { width, height }, 'Flutter view must follow the viewport');
  return snapshot;
}

try {
  await fs.access(path.join(build, 'main.dart.wasm'));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  chrome = spawn(chromePath, [
    '--headless=new', '--no-sandbox', '--enable-unsafe-swiftshader',
    '--use-angle=swiftshader', '--remote-debugging-port=0',
    `--user-data-dir=${profile}`, 'about:blank',
  ], { stdio: 'ignore' });
  chrome.on('error', error => failures.push(error.message));
  const port = await waitFor(async () => {
    if (failures.length) throw new Error(failures.join('\n'));
    try {
      return (await fs.readFile(path.join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0];
    } catch { return null; }
  }, 'Chrome DevTools port');
  const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  ws = new WebSocket(tabs.find(tab => tab.type === 'page').webSocketDebuggerUrl);
  await once(ws, 'open');
  ws.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const request = pending.get(message.id);
      if (!request) return;
      pending.delete(message.id);
      clearTimeout(request.timer);
      if (message.error) request.reject(new Error(JSON.stringify(message.error)));
      else request.resolve(message.result);
    } else if (message.method === 'Runtime.exceptionThrown') {
      const exception = message.params.exceptionDetails;
      errors.push(exception.exception?.description ?? exception.text);
    } else if (message.method === 'Runtime.executionContextsCleared') {
      errors = [];
    }
  });
  await send('Runtime.enable');
  await send('Page.enable');

  for (const renderer of ['skwasm', 'canvaskit']) {
    for (const depth of [20, 150, 200]) {
      const label = `${renderer}, depth=${depth}`;
      try {
        await resize(1133, 744);
        caseId = `${renderer}-${depth}-${Date.now()}`;
        await send('Page.navigate', {
          url: `${origin}/?renderer=${renderer}&depth=${depth}&case=${caseId}`,
        });
        errors = [];
        await checkSize(1133, 744);
        const resources = await evaluate(`performance.getEntriesByType('resource').map(e => e.name)`);
        assert(resources.some(url => url.endsWith(renderer === 'skwasm' ? '/main.dart.wasm' : '/main.dart.js')),
          'verify actual compilation target, including CanvasKit fallback');
        for (let cycle = 0; cycle < 2; cycle++) {
          for (const [width, height] of [[1512, 982], [700, 900], [500, 900], [1133, 744]]) {
            await resize(width, height);
            await checkSize(width, height);
          }
        }
        console.log(`PASS ${label}: 8 resizes; rendered width/height/font, view size and State retained`);
      } catch (error) {
        failures.push(`${label}: ${error.message}`);
        console.error(`FAIL ${label}: ${error.message}`);
        for (const exception of errors) console.error(exception);
        console.error('Last snapshot:', await evaluate(
          'globalThis.screenUtilResizeSnapshot ? screenUtilResizeSnapshot() : null',
        ));
      }
    }
  }
} finally {
  for (const request of pending.values()) clearTimeout(request.timer);
  ws?.close();
  if (chrome && chrome.exitCode === null) {
    const exited = once(chrome, 'exit');
    chrome.kill();
    await Promise.race([exited, delay(3000)]);
  }
  server.closeAllConnections();
  server.close();
  await fs.rm(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}

if (failures.length) process.exitCode = 1;
