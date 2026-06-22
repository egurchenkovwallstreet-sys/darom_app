# SMTP — код админа на почту (2FA)

При входе в **админ-панель** нужны **два** кода:

1. **Mobile ID** на телефон (~3–6 ₽) — уже работает
2. **6 цифр на email** — этот файл

Пока SMTP не настроен, код почты виден только в логах сервера (`pm2 logs`). После настройки — письмо приходит на **e.gurchenkov@yandex.ru** (или другой адрес из `ADMIN_EMAIL`).

---

## 1. Пароль приложения Yandex (один раз)

Пароль от почты **не подходит** — нужен отдельный «пароль приложения».

1. Откройте в браузере: https://mail.yandex.ru  
2. Войдите в ящик **e.gurchenkov@yandex.ru** (или тот, что указан в `ADMIN_EMAIL`).
3. Нажмите **шестерёнку** (Настройки) → **Безопасность**.
4. Включите **«Пароли приложений»** (если выключено).
5. Создайте пароль для приложения, например имя **«Darom admin»**.
6. Скопируйте **16 символов** (без пробелов) — он показывается **один раз**.

⚠️ Этот пароль **не отправляйте** в чаты и **не коммитьте** в Git.

---

## 2. Настройка на сервере (VNC Timeweb)

Откройте **консоль VNC** на сервере Timeweb (как при настройке SMS).

**Шаг 1 — открыть файл настроек:**

```bash
nano /opt/darom_app/backend/.env
```

**Шаг 2 — добавить в конец файла** (подставьте **свой** пароль приложения):

```env
# --- Админ: код на почту (2FA) ---
ADMIN_EMAIL=e.gurchenkov@yandex.ru
ADMIN_PHONE=79138931428
ADMIN_EMAIL_MOCK=false
SMTP_HOST=smtp.yandex.ru
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=e.gurchenkov@yandex.ru
SMTP_PASS=ваш_пароль_приложения_16_символов
SMTP_FROM=Даром <e.gurchenkov@yandex.ru>
```

Сохранить: `Ctrl+O`, Enter, `Ctrl+X`.

**Шаг 3 — обновить код и перезапустить сервер:**

```bash
cd /opt/darom_app
git pull
cd backend
npm install
pm2 restart darom-api --update-env
```

**Успех:** в логах должна быть строка вида:

```text
✓ Admin email SMTP: smtp.yandex.ru:465 → e.gurchenkov@yandex.ru
```

Посмотреть логи:

```bash
pm2 logs darom-api --lines 30
```

---

## 3. Проверка

**A. Health API**

Откройте в браузере:

https://darom-app.online/api/health

Должно быть примерно так:

```json
"adminEmail": {
  "mock": false,
  "smtpConfigured": true,
  "ready": true
}
```

**B. Вход в админку**

1. Откройте https://darom-app.online/
2. Войдите под admin-телефоном → **Профиль** → **Админ-панель**
3. Нажмите **«Получить коды»**
4. Подтвердите **Mobile ID** на телефоне
5. Откройте почту **e.gurchenkov@yandex.ru** — письмо **«Код входа в админ-панель «Даром»»**
6. Введите **6 цифр с почты** → вход в кабинет

В тестовом режиме (`ADMIN_EMAIL_MOCK=true`) код почты показывался на экране — в боевом режиме **на экране его не будет**.

---

## 4. Если письмо не приходит

| Проблема | Решение |
|----------|---------|
| `adminEmail.mock: true` в `/api/health` | На сервере: `ADMIN_EMAIL_MOCK=false` и заполните SMTP_* |
| `smtpConfigured: false` | Заполните `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` |
| Ошибка «Invalid login» в логах | Создайте **новый пароль приложения** Yandex, обновите `SMTP_PASS` |
| Письмо в «Спам» | Отметьте «Не спам», добавьте отправителя в контакты |
| Ошибка на экране «Не удалось отправить код на почту» | `pm2 logs darom-api --lines 50` — там текст ошибки SMTP |

---

## 5. Локальная разработка (ПК)

На компьютере в `backend/.env` оставьте:

```env
ADMIN_EMAIL_MOCK=true
```

Код почты будет в консоли backend и на экране входа в админку — SMS/Mobile ID не списываются с баланса при `SMS_MOCK=true`.

---

## Другие почтовые сервисы

| Сервис | SMTP_HOST | Порт | Примечание |
|--------|-----------|------|------------|
| Yandex | smtp.yandex.ru | 465 | Пароль приложения |
| Mail.ru | smtp.mail.ru | 465 | Пароль для внешнего приложения |
| Gmail | smtp.gmail.com | 587 | `SMTP_SECURE=false`, App Password |

Для Gmail пример:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
```
