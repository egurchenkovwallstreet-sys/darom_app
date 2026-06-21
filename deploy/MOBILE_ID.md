# SMS Aero — Мобильная авторизация (Mobile ID)

Дешевле обычного SMS (~**3,39–5,79 ₽** за попытку вместо **46 ₽** на Билайне).

Как работает для пользователя:
1. Вводит номер → нажимает «Подтвердить номер»
2. **~95%** — push «Подтвердить» на телефоне (Seamless / SIM-PUSH), без кода
3. **~5%** — приходит SMS с кодом, пользователь вводит 4 цифры

---

## 1. Кабинет SMS Aero

1. [smsaero.ru](https://smsaero.ru) → **Настройки** → **Мобильная авторизация**
2. Нажмите **«+ Добавить»**
3. Укажите сайт: **darom-app.online**
4. Дождитесь одобрения интеграции
5. Запомните **имя отправителя (sign)** для Mobile ID — его дадут в кабинете

Подробнее о тарифах: [smsaero.ru/price/mobilnaya-avtorizaciya](https://smsaero.ru/price/mobilnaya-avtorizaciya/)

---

## 2. Сервер (VNC)

**Миграции** (один раз):

```bash
cd /opt/darom_app
cat backend/db/migrate_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
```

**Файл `.env`:**

```bash
nano /opt/darom_app/backend/.env
```

```env
SMS_PROVIDER=smsaero
SMS_AERO_EMAIL=ваш_email@yandex.ru
SMS_AERO_API_KEY=ваш_api_ключ
SMS_AUTH_MODE=mobile_id
SMS_AERO_MOBILE_ID_SIGN=имя_из_кабинета_Mobile_ID
SMS_MOCK=false
PUBLIC_BASE_URL=https://darom-app.online
```

Удалите дублирующую строку **`SMS_MOCK=true`** внизу файла, если она есть.

```bash
cd /opt/darom_app
git pull
pm2 restart darom-api --update-env
pm2 logs darom-api --lines 10
```

**Успех в логах:**

```
✓ SMS Aero Mobile ID: ВАШ_SIGN, webhook https://darom-app.online/api/auth/mobile-id/webhook
```

---

## 3. Проверка

**Обычный пользователь:**
1. Новый пользователь → **опубликовать объявление** или **написать в чат**
2. В диалоге — «Подтвердить номер»
3. На телефоне — push **или** SMS с кодом

**Партнёр / блогер:**
1. «Я партнёр / блогер» → код + телефон → «Продолжить»
2. Экран Mobile ID → push **или** SMS с кодом
3. Имя → PIN → главная

В SMS Aero → **История** — стоимость ~**3–6 ₽**, не 46 ₽

---

## 4. Режимы в `.env`

| Переменная | Значение |
|------------|----------|
| `SMS_AUTH_MODE=mobile_id` | Mobile ID (рекомендуется) |
| `SMS_AUTH_MODE=sms` | Старый канал `/v2/sms/send` (дорого без шаблона) |
| `SMS_MOCK=true` | Тестовый код на экране, 0 ₽ |

---

## 5. Webhook

SMS Aero шлёт статусы на:

`https://darom-app.online/api/auth/mobile-id/webhook`

Должен быть доступен по HTTPS (у вас уже есть). Ответ сервера — **HTTP 200**.
