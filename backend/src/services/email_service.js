const dns = require('dns');
const nodemailer = require('nodemailer');
const config = require('../config');

function ipv4Lookup(hostname, _options, callback) {
  dns.lookup(hostname, { family: 4 }, callback);
}

function buildTransportOptions({ port, secure }) {
  return {
    host: config.smtp.host,
    port,
    secure,
    auth: {
      user: config.smtp.user,
      pass: config.smtp.pass,
    },
    connectionTimeout: 10_000,
    greetingTimeout: 10_000,
    socketTimeout: 15_000,
    lookup: ipv4Lookup,
    ...(secure ? {} : { requireTLS: true }),
  };
}

function transportAttempts() {
  const primary = {
    port: config.smtp.port,
    secure: config.smtp.secure,
    label: `${config.smtp.port}${config.smtp.secure ? ' SSL' : ' STARTTLS'}`,
  };

  const fallbacks = [];
  if (primary.port === 465 && primary.secure) {
    fallbacks.push({ port: 587, secure: false, label: '587 STARTTLS (fallback)' });
  } else if (primary.port === 587 && !primary.secure) {
    fallbacks.push({ port: 465, secure: true, label: '465 SSL (fallback)' });
  }

  return [primary, ...fallbacks];
}

function isConnectionError(err) {
  const msg = String(err?.message || err).toLowerCase();
  return (
    msg.includes('timeout') ||
    msg.includes('timed out') ||
    msg.includes('econnrefused') ||
    msg.includes('econnreset') ||
    msg.includes('enotfound') ||
    msg.includes('connect')
  );
}

function generateEmailCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function sendAdminEmailCode({ to, code }) {
  const subject = 'Код входа в админ-панель «Даром»';
  const text = `Ваш код для входа в админ-панель: ${code}\n\nКод действует 10 минут.`;
  const html = `
    <p>Ваш код для входа в админ-панель «Даром»:</p>
    <p style="font-size:24px;font-weight:bold;letter-spacing:2px">${code}</p>
    <p>Код действует 10 минут. Если вы не запрашивали вход — проигнорируйте письмо.</p>
  `.trim();
  const mailOptions = {
    from: config.smtp.from,
    to,
    subject,
    text,
    html,
  };

  if (config.adminEmailMock || !config.smtp.host) {
    console.log(`[ADMIN EMAIL MOCK] to=${to} code=${code}`);
    return { mock: true, debugCode: code };
  }

  if (!config.smtp.user || !config.smtp.pass) {
    console.error('[ADMIN EMAIL] SMTP_HOST задан, но SMTP_USER или SMTP_PASS пусты');
    return { mock: false, error: 'SMTP не настроен: заполните SMTP_USER и SMTP_PASS в backend/.env' };
  }

  const attempts = transportAttempts();
  let lastError = null;

  for (let i = 0; i < attempts.length; i += 1) {
    const attempt = attempts[i];
    const transport = nodemailer.createTransport(
      buildTransportOptions({ port: attempt.port, secure: attempt.secure })
    );

    try {
      await transport.sendMail(mailOptions);
      console.log(`[ADMIN EMAIL] sent to=${to} via ${config.smtp.host}:${attempt.label}`);
      return { mock: false, sent: true };
    } catch (err) {
      lastError = err;
      console.error(
        `[ADMIN EMAIL] ${config.smtp.host}:${attempt.label} failed: ${err.message}`
      );
      if (i < attempts.length - 1 && isConnectionError(err)) {
        console.warn('[ADMIN EMAIL] пробуем запасной порт SMTP…');
        continue;
      }
      break;
    } finally {
      transport.close();
    }
  }

  const message = lastError?.message || 'Не удалось отправить письмо';
  if (isConnectionError(lastError)) {
    return {
      mock: false,
      error:
        'Connection timeout: сервер не может подключиться к SMTP (порты 465/587 заблокированы хостингом)',
      connectionBlocked: true,
    };
  }

  return { mock: false, error: message };
}

module.exports = {
  generateEmailCode,
  sendAdminEmailCode,
};
