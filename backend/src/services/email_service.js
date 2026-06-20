const config = require('../config');

function generateEmailCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function sendAdminEmailCode({ to, code }) {
  const subject = 'Код входа в админ-панель «Дарom»';
  const text = `Ваш код для входа в админ-панель: ${code}\n\nКод действует 10 минут.`;

  if (config.adminEmailMock || !config.smtp.host) {
    console.log(`[ADMIN EMAIL MOCK] to=${to} code=${code}`);
    return { mock: true, debugCode: code };
  }

  // SMTP через nodemailer не подключён — используйте ADMIN_EMAIL_MOCK=true или настройте SMTP позже.
  // Пока логируем и возвращаем mock для разработки.
  console.log(`[ADMIN EMAIL] to=${to} (SMTP не настроен, см. backend/.env)`);
  return { mock: true, debugCode: code };
}

module.exports = {
  generateEmailCode,
  sendAdminEmailCode,
};
