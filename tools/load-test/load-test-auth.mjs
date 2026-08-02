/**
 * Нагрузочный тест чатов (нужна сессия).
 *
 * 1. Войдите в приложение в Chrome, DevTools → Application → Cookies → darom_session
 * 2. Запуск:
 *    node tools/load-test/load-test-auth.mjs --cookie=TOKEN --phone=9001234567 --users=10 --seconds=30
 */

const BASE = (process.argv.find((a) => a.startsWith('--base='))?.split('=')[1] ||
  'https://darom-app.online').replace(/\/$/, '');

const COOKIE = process.argv.find((a) => a.startsWith('--cookie='))?.split('=')[1];
const PHONE = process.argv.find((a) => a.startsWith('--phone='))?.split('=')[1];
const VUS = parseInt(process.argv.find((a) => a.startsWith('--users='))?.split('=')[1] || '10', 10);
const DURATION_SEC = parseInt(process.argv.find((a) => a.startsWith('--seconds='))?.split('=')[1] || '30', 10);

if (!COOKIE || !PHONE) {
  console.error('Нужны --cookie=... и --phone=...');
  console.error('Cookie darom_session из браузера после входа.');
  process.exit(1);
}

async function fetchTimed(path) {
  const start = performance.now();
  try {
    const res = await fetch(`${BASE}${path}`, {
      headers: { Cookie: `darom_session=${COOKIE}` },
      signal: AbortSignal.timeout(15000),
    });
    const body = await res.text();
    return {
      ok: res.ok,
      status: res.status,
      ms: performance.now() - start,
      body: body.slice(0, 200),
      rateLimited: res.status === 429,
    };
  } catch (e) {
    return { ok: false, status: 0, ms: performance.now() - start, error: e.message };
  }
}

function percentile(arr, p) {
  if (!arr.length) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  return sorted[Math.ceil((p / 100) * sorted.length) - 1];
}

async function virtualUser(stats, stopAt) {
  while (Date.now() < stopAt) {
    const chats = await fetchTimed(`/api/chats?phone=${encodeURIComponent(PHONE)}`);
    stats.record('GET /api/chats', chats);

    const unread = await fetchTimed(`/api/chats/unread-summary?phone=${encodeURIComponent(PHONE)}`);
    stats.record('GET /api/chats/unread-summary', unread);

    await new Promise((r) => setTimeout(r, 1000));
  }
}

function createStats() {
  const byEndpoint = {};
  return {
    record(endpoint, r) {
      if (!byEndpoint[endpoint]) {
        byEndpoint[endpoint] = { times: [], statuses: {}, rateLimited: 0 };
      }
      const s = byEndpoint[endpoint];
      s.times.push(r.ms);
      const st = r.status || 'ERR';
      s.statuses[st] = (s.statuses[st] || 0) + 1;
      if (r.rateLimited) s.rateLimited++;
    },
    summary() {
      const out = {};
      for (const [ep, s] of Object.entries(byEndpoint)) {
        out[ep] = {
          count: s.times.length,
          p50_ms: Math.round(percentile(s.times, 50)),
          p95_ms: Math.round(percentile(s.times, 95)),
          rateLimited: s.rateLimited,
          statuses: s.statuses,
        };
      }
      return out;
    },
  };
}

async function main() {
  console.log(`\n=== Даром chat load test ===`);
  console.log(`Users: ${VUS}, ${DURATION_SEC}s, phone=${PHONE}\n`);

  const stats = createStats();
  const stopAt = Date.now() + DURATION_SEC * 1000;
  await Promise.all(Array.from({ length: VUS }, () => virtualUser(stats, stopAt)));

  const summary = stats.summary();
  for (const [ep, s] of Object.entries(summary)) {
    console.log(`${ep}: ${s.count} req, p50=${s.p50_ms}ms p95=${s.p95_ms}ms`, s.statuses);
    if (s.rateLimited) console.log(`  ⚠ 429: ${s.rateLimited}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
