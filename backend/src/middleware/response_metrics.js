const MAX_SAMPLES = 200;
const samples = [];

function recordResponseTime(ms) {
  samples.push(ms);
  if (samples.length > MAX_SAMPLES) {
    samples.shift();
  }
}

function percentile(arr, p) {
  if (!arr.length) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, idx)];
}

function getResponseMetrics() {
  const mem = process.memoryUsage();
  return {
    uptime_sec: Math.round(process.uptime()),
    heap_used_mb: Math.round(mem.heapUsed / 1024 / 1024),
    heap_total_mb: Math.round(mem.heapTotal / 1024 / 1024),
    rss_mb: Math.round(mem.rss / 1024 / 1024),
    samples: samples.length,
    avg_ms: samples.length ? Math.round(samples.reduce((a, b) => a + b, 0) / samples.length) : 0,
    p95_ms: Math.round(percentile(samples, 95)),
  };
}

function shouldSkipMetrics(req) {
  return req.path === '/api/health' || req.path.startsWith('/api/photos/');
}

function responseMetricsMiddleware(req, res, next) {
  if (shouldSkipMetrics(req)) {
    return next();
  }

  const start = process.hrtime.bigint();
  res.on('finish', () => {
    const ms = Number(process.hrtime.bigint() - start) / 1e6;
    recordResponseTime(ms);
  });
  return next();
}

module.exports = {
  responseMetricsMiddleware,
  getResponseMetrics,
};
