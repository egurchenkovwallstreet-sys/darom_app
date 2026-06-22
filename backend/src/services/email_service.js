const nodemailer = require('nodemailer');
const config = require('../config');

let transporter = null;

function getTransporter() {
  if (transporter) return transporter;
  if (!config.smtp.host) return null;

  transporter = nodemailer.createTransport({
    host: config.smtp.host,
    port: config.smtp.port,
    secure: config.smtp.secure,
    auth: {
      user: config.smtp.user,
      pass: config.smtp.pass,
    },
  });
  return transporter;
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

  if (config.adminEmailMock || !config.smtp.host) {
    console.log(`[ADMIN EMAIL MOCK] to=${to} code=${code}`);
    return { mock: true, debugCode: code };
  }

  if (!config.smtp.user || !config.smtp.pass) {
    console.error('[ADMIN EMAIL] SMTP_HOST задан, но SMTP_USER или SMTP_PASS пусты');
    return { mock: false, error: 'SMTP не настроен: заполните SMTP_USER и SMTP_PASS в backend/.env' };
  }

  try {
    const transport = getTransporter();
    await transport.sendMail({
      from: config.smtp.from,
      to,
      subject,
      text,
      html,
    });
    console.log(`[ADMIN EMAIL] sent to=${to}`);
    return { mock: false, sent: true };
  } catch (err) {
    console.error('[ADMIN EMAIL] send failed:', err.message);
    return { mock: false, error: err.message };
  }
}

module.exports = {
  generateEmailCode,
  sendAdminEmailCode,
};
