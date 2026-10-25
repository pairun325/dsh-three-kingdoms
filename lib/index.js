/**
 * dsh-three-kingdoms — 一个按钮：《关羽之歌》。
 *
 * 按一下：如果网易云正在出声，就什么都不做；没声就 `cloudmusic.exe --webcmd="orpheus://song/<id>"`
 * 把歌点开，必要时再补一记媒体播放键。全程不看屏幕、不抢键鼠。
 */
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const name = 'dsh-three-kingdoms';
export const inject = ['tools', 'webServer'];

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = path.resolve(HERE, '..');
const HELPER = path.join(PLUGIN_ROOT, 'helper', 'play.ps1');
const ROUTE_PREFIX = '/three-kingdoms';
const SONG = { id: '1349225260', title: '关羽之歌', album: 'Three Kingdoms', artist: '赵季平' };

const POWERSHELL_CANDIDATES = [
  'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
  'C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe',
];

function resolvePowershell() {
  for (const candidate of POWERSHELL_CANDIDATES) {
    if (existsSync(candidate)) return candidate;
  }
  return 'powershell.exe';
}

export function playSong() {
  return new Promise((resolve) => {
    if (!existsSync(HELPER)) {
      resolve({ ok: false, state: 'error', message: `缺少脚本：${HELPER}` });
      return;
    }
    const child = spawn(
      resolvePowershell(),
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', HELPER],
      { windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] },
    );
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => {
      try {
        child.kill();
      } catch {}
      resolve({ ok: false, state: 'timeout', message: '脚本 30 秒没返回' });
    }, 30000);
    child.stdout.on('data', (chunk) => {
      stdout += String(chunk);
    });
    child.stderr.on('data', (chunk) => {
      stderr += String(chunk);
    });
    child.on('error', (error) => {
      clearTimeout(timer);
      resolve({ ok: false, state: 'error', message: String(error?.message ?? error) });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      const line = stdout
        .split(/\r?\n/)
        .map((item) => item.trim())
        .filter((item) => item.startsWith('{'))
        .pop();
      if (line === undefined) {
        resolve({ ok: false, state: 'error', message: (stderr.trim() || `exit ${code}`).slice(0, 300) });
        return;
      }
      try {
        resolve(JSON.parse(line));
      } catch {
        resolve({ ok: false, state: 'error', message: line.slice(0, 300) });
      }
    });
  });
}

function sendJson(res, status, body) {
  const text = JSON.stringify(body);
  res.statusCode = status;
  res.setHeader('content-type', 'application/json; charset=utf-8');
  res.setHeader('cache-control', 'no-store');
  res.end(text);
}

const TOOL_DESCRIPTION =
  '按一下播《关羽之歌》（专辑 Three Kingdoms，赵季平）。网易云已经在出声就什么都不做；' +
  '没声音就用 orpheus:// 命令把歌点开，必要时补一记媒体播放键。返回 {ok,state,peak,action,message}。';

export function apply(ctx) {
  const disposers = [];

  ctx.tools.register({
    name: 'three_kingdoms_play',
    description: TOOL_DESCRIPTION,
    parameters: { type: 'object', properties: {}, additionalProperties: false },
    output: {
      schema: { type: 'object' },
      render: (_args, value) => [{ type: 'text', text: value?.message ?? '已执行' }],
    },
    async execute() {
      return playSong();
    },
    presentCall() {
      return { card: 'generic', title: 'three_kingdoms_play', kind: 'other' };
    },
  });

  if (ctx.webServer !== undefined && ctx.webServer !== null) {
    disposers.push(
      ctx.webServer.register({
        kind: 'prefix',
        path: ROUTE_PREFIX,
        handler: async (req, res) => {
          const connection = ctx.connection;
          if (connection !== undefined && connection !== null && typeof connection.requestRejection === 'function') {
            const rejection = connection.requestRejection(req);
            if (rejection !== undefined) {
              res.statusCode = rejection;
              res.end();
              return;
            }
          }
          const url = new URL(String(req.url ?? '/'), 'http://localhost');
          const pathname = url.pathname;
          try {
            if (pathname === `${ROUTE_PREFIX}/song` && req.method === 'GET') {
              sendJson(res, 200, { ok: true, song: SONG });
              return;
            }
            if (pathname === `${ROUTE_PREFIX}/play` && req.method === 'POST') {
              const result = await playSong();
              sendJson(res, 200, { ok: result.ok === true, song: SONG, result });
              return;
            }
            sendJson(res, 404, { ok: false, message: `no route for ${pathname}` });
          } catch (error) {
            sendJson(res, 500, { ok: false, message: String(error?.message ?? error) });
          }
        },
      }),
    );
  }

  return () => {
    for (const dispose of disposers.splice(0)) {
      try {
        dispose();
      } catch {}
    }
  };
}

export default { name, inject, apply };
