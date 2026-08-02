/**
 * Нагрузочный тест API «Даром».
 * Запуск: node tools/load-test/load-test.mjs [--base=https://darom-app.online] [--users=30] [--seconds=45]
 *
 * Симулирует поведение приложения: лента (5с), категории (2с), health.
 * Все запросы с одного IP — срабатывает rate limit 1000 req/min.
 */

const BASE = (process.argv.find((a) => a.startsWith('--base='))?.split('=')[1] ||
  'https://darom-app.online').replace(/\/$/, '');

const VUS = parseInt(process.argv.find((a) => a.startsWith('--users='))?.split('=')[1] || '30', 10);
const DURATION_SEC = parseInt(process.argv.find((a) => a.startsWith('--seconds='))?.split('=')[1] || '45', 10);

const INTERVALS = {
  home: 5000,
  category: 2000,
  health: 10000,
};

const MOSCOW = { lat: 55.7558, lng: 37.6173, radius_km: 10 };
const CATEGORY = encodeURIComponent('Электроника');
const SUBCATEGORY = encodeURIComponent('Телефоны');

async function fetchTimed(url, opts = {}) {
  const start = performance.now();
  try {
    const res = await fetch(url, { ...opts, signal: AbortSignal.timeout(15000) });
    const body = await res.text();
    const ms = performance.now() - start;
    return { ok: res.ok, status: res.status, ms, body: body.slice(0, 200), rateLimited: res.status === 429 };
  } catch (e) {
    return { ok: false, status: 0, ms: performance.now() - start, error: e.message, rateLimited: false };
  }
}

function percentile(arr, p) {
  if (!arr.length) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, idx)];
}

async function virtualUser(id, stats, stopAt) {
  let tick = 0;
  const { lat, lng, radius_km } = MOSCOW;
  while (Date.now() < stopAt) {
    tick++;
    const tasks = [];

    // Главная — nearby каждые 5 с (как home_screen)
    tasks.push(
      fetchTimed(
        `${BASE}/api/listings/nearby?lat=${lat}&lng=${lng}&radius_km=${radius_km}`
      ).then((r) => stats.record('GET /api/listings/nearby', r))
    );

    // Категории — счётчики + лента каждые 2 с (упрощённо: каждый тик)
    tasks.push(
      fetchTimed(`${BASE}/api/listings/subcategory-counts?category=${CATEGORY}`).then((r) =>
        stats.record('GET /api/listings/subcategory-counts', r)
      )
    );
    tasks.push(
      fetchTimed(
        `${BASE}/api/listings?category=${CATEGORY}&subcategory=${SUBCATEGORY}&lat=${lat}&lng=${lng}`
      ).then((r) => stats.record('GET /api/listings', r))
    );

    if (tick % 2 === 0) {
      tasks.push(
        fetchTimed(`${BASE}/api/health`).then((r) => stats.record('GET /api/health', r))
      );
    }

    await Promise.all(tasks);
    await new Promise((r) => setTimeout(r, INTERVALS.home));
  }
}

function createStats() {
  const byEndpoint = {};
  return {
    record(endpoint, r) {
      if (!byEndpoint[endpoint]) {
        byEndpoint[endpoint] = { times: [], errors: [], rateLimited: 0, statuses: {} };
      }
      const s = byEndpoint[endpoint];
      s.times.push(r.ms);
      const st = r.status || 'ERR';
      s.statuses[st] = (s.statuses[st] || 0) + 1;
      if (r.rateLimited) s.rateLimited++;
      if (!r.ok) s.errors.push({ status: r.status, error: r.error, body: r.body });
    },
    summary() {
      const out = {};
      for (const [ep, s] of Object.entries(byEndpoint)) {
        out[ep] = {
          count: s.times.length,
          p50_ms: Math.round(percentile(s.times, 50)),
          p95_ms: Math.round(percentile(s.times, 95)),
          p99_ms: Math.round(percentile(s.times, 99)),
          max_ms: Math.round(Math.max(...s.times, 0)),
          rateLimited: s.rateLimited,
          statuses: s.statuses,
          sampleErrors: s.errors.slice(0, 3),
        };
      }
      return out;
    },
  };
}

async function main() {
  console.log(`\n=== Даром load test ===`);
  console.log(`Base: ${BASE}`);
  console.log(`Virtual users: ${VUS}, duration: ${DURATION_SEC}s`);
  console.log(`Note: all requests from ONE IP → rate limit 1000/min applies\n`);

  const stats = createStats();
  const stopAt = Date.now() + DURATION_SEC * 1000;
  const start = Date.now();

  const users = Array.from({ length: VUS }, (_, i) => virtualUser(i, stats, stopAt));
  await Promise.all(users);

  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  const summary = stats.summary();
  let totalReq = 0;
  let total429 = 0;
  let totalErr = 0;

  console.log(`Completed in ${elapsed}s\n`);
  for (const [ep, s] of Object.entries(summary)) {
    totalReq += s.count;
    total429 += s.rateLimited;
    totalErr += (s.statuses[0] || 0) + (s.statuses['ERR'] || 0);
    console.log(`${ep}:`);
    console.log(`  requests: ${s.count}, p50=${s.p50_ms}ms p95=${s.p95_ms}ms p99=${s.p99_ms}ms max=${s.max_ms}ms`);
    console.log(`  statuses: ${JSON.stringify(s.statuses)}`);
    if (s.rateLimited) console.log(`  ⚠ rate limited (429): ${s.rateLimited}`);
    if (s.sampleErrors.length) console.log(`  errors sample: ${JSON.stringify(s.sampleErrors)}`);
    console.log('');
  }

  const reqPerMin = Math.round((totalReq / parseFloat(elapsed)) * 60);
  console.log(`TOTAL: ${totalReq} requests (~${reqPerMin}/min from this IP)`);
  if (total429 > 0) {
    console.log(`⚠ ${total429} responses were 429 — rate limit hit (expected with many VUs from one IP)`);
  }
  if (totalErr > 0 && total429 === 0) {
    console.log(`⚠ ${totalErr} network/other errors — investigate`);
  }
  if (total429 === 0 && totalErr === 0) {
    console.log(`✓ No 429 or network errors at this load level`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
