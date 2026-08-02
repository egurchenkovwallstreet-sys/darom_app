const express = require('express');
const path = require('path');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const config = require('./config');
const { ensureUploadDir } = require('./utils/photo_storage');
const healthRouter = require('./routes/health');
const listingsRouter = require('./routes/listings');
const usersRouter = require('./routes/users');
const authRouter = require('./routes/auth');
const dealsRouter = require('./routes/deals');
const photosRouter = require('./routes/photos');
const favoritesRouter = require('./routes/favorites');
const chatsRouter = require('./routes/chats');
const supportRouter = require('./routes/support');
const moderationRouter = require('./routes/moderation');
const partnersRouter = require('./routes/partners');
const adminRouter = require('./routes/admin');
const deployWebRouter = require('./routes/deploy_web');
const paymentsRouter = require('./routes/payments');
const configRouter = require('./routes/config');
const deployBackendRouter = require('./routes/deploy_backend');
const dailyReportsRouter = require('./routes/daily_reports');
const { apiGeneralLimiter, authGeneralLimiter } = require('./middleware/rate_limit');
const { responseMetricsMiddleware } = require('./middleware/response_metrics');
const db = require('./db/pool');
const { startDailyReportScheduler } = require('./services/daily_report_scheduler');
const { startReservationExpiryScheduler } = require('./services/reservation_expiry_scheduler');

const app = express();

app.set('trust proxy', 1);

const corsOrigins = new Set(config.corsOrigins);
app.use(
  cors({
    origin(origin, callback) {
      if (!origin || corsOrigins.has(origin)) {
        callback(null, origin || true);
        return;
      }
      callback(null, false);
    },
    credentials: true,
  })
);
app.use(cookieParser());
app.use(express.json());
app.use(responseMetricsMiddleware);

app.use('/api/auth', authGeneralLimiter);
app.use('/api', apiGeneralLimiter);

if (config.photoStorage !== 's3') {
  ensureUploadDir();
  app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
}

app.get('/', (_req, res) => {
  res.json({
    message: 'Даром API работает',
    health: '/api/health',
    listings: '/api/listings?category=Одежда&subcategory=Мужская',
    users: 'POST /api/users { phone, name }',
  });
});

app.use('/api/health', healthRouter);
app.use('/api/config', configRouter);
app.use('/api/photos', photosRouter);
app.use('/api/listings', listingsRouter);
app.use('/api/users', usersRouter);
app.use('/api/auth', authRouter);
app.use('/api/deals', dealsRouter);
app.use('/api/favorites', favoritesRouter);
app.use('/api/chats', chatsRouter);
app.use('/api/support', supportRouter);
app.use('/api/moderation', moderationRouter);
app.use('/api/partners', partnersRouter);
app.use('/api/admin', adminRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/deploy-web', deployWebRouter);
app.use('/api/deploy-backend', deployBackendRouter);
app.use('/api/daily-reports', dailyReportsRouter);

const server = app.listen(config.port, () => {
  console.log(`Darom API: http://localhost:${config.port}`);
  console.log(`Фото: ${config.photoStorage === 's3' ? 'Yandex Object Storage' : 'локально (/uploads)'}`);
  startReservationExpiryScheduler(db);
  startDailyReportScheduler(db);
});

function shutdown() {
  server.close(() => process.exit(0));
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Порт ${config.port} уже занят. Закройте другой backend (Ctrl+C) или выполните:`);
    console.error(`  netstat -ano | findstr :${config.port}`);
    console.error('  taskkill /PID <номер> /F');
    process.exit(1);
  }
  throw err;
});
