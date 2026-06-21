# Робокасса — подключение «Даром»

> Пошагово для новичка. Сначала GitHub, потом сервер.

## Что оплачивается

| Услуга | Цена |
|--------|------|
| Супер даритель | **99₽** |
| Пакет заборов 1 | **149₽** |
| Пакет заборов 2 | **299₽** |
| Пакет заборов 3 | **499₽** |

---

## Часть 1 — Регистрация в Робокассе

1. Откройте https://robokassa.ru → регистрация (нужно **ИП или ООО**).
2. **Мои магазины** → создайте магазин **«Даром»**.
3. URL сайта: `https://darom-app.online/`

### Технические настройки магазина

| Поле | Значение | Метод |
|------|----------|--------|
| **Result URL** | `https://darom-app.online/api/payments/robokassa/result` | **POST** |
| **Success URL** | `https://darom-app.online/api/payments/robokassa/success` | GET |
| **Fail URL** | `https://darom-app.online/api/payments/robokassa/fail` | GET |
| **Алгоритм хеша** | **MD5** | — |

4. Сгенерируйте **Пароль #1** и **Пароль #2** (боевые и тестовые).
5. Нажмите **Сохранить**. Скопируйте пароли в блокнот — в кабинете их не покажут снова.

Запишите **Идентификатор магазина** (Merchant Login), например `darom-app`.

---

## Часть 2 — GitHub (код уже в проекте)

**Терминал 1 — PowerShell:**

```powershell
cd C:\Users\User\Desktop\darom_app
git add .
git commit -m "Робокасса: оплата Супер даритель и пакеты заборов."
git push
```

Дождитесь **зелёной галочки** в GitHub Actions (~5–10 мин).

---

## Часть 3 — Сервер Timeweb (консоль VNC)

```bash
cd /opt/darom_app
git pull
cat backend/db/migrate_payments.sql | docker exec -i darom_db psql -U darom -d darom
nano /opt/darom_app/backend/.env
```

В конец `.env` добавьте (подставьте **свои** значения):

```env
PUBLIC_BASE_URL=https://darom-app.online

ROBOKASSA_MERCHANT_LOGIN=darom-app
ROBOKASSA_PASSWORD1=ваш_боевой_пароль_1
ROBOKASSA_PASSWORD2=ваш_боевой_пароль_2
ROBOKASSA_TEST_PASSWORD1=ваш_тестовый_пароль_1
ROBOKASSA_TEST_PASSWORD2=ваш_тестовый_пароль_2
ROBOKASSA_TEST_MODE=true
PAYMENT_MOCK=false
```

| Переменная | Значение |
|------------|----------|
| `PAYMENT_MOCK=false` | Реальная оплата через Робокассу |
| `PAYMENT_MOCK=true` | Тест без списания (как раньше) |
| `ROBOKASSA_TEST_MODE=true` | Тестовые платежи Робокассы |
| `ROBOKASSA_TEST_MODE=false` | Боевые платежи (реальные деньги) |

Сохраните: `Ctrl+O`, Enter, `Ctrl+X`.

```bash
cd /opt/darom_app/backend
npm install
pm2 restart darom-api
```

**Успех:** `darom-api` — **online**.

---

## Часть 4 — Проверка

### Тестовая оплата (ROBOKASSA_TEST_MODE=true)

1. Откройте https://darom-app.online/
2. Дойдите до диалога **Супер даритель 99₽** или **пакет заборов 149₽**
3. Нажмите **Оплатить** → откроется страница Робокассы
4. Оплатите **тестовым способом** (подсказки в личном кабинете Робокассы)
5. После успеха — страница «Спасибо!» → **На главную**

### Боевая оплата

Только после успешного теста:

```env
ROBOKASSA_TEST_MODE=false
```

`pm2 restart darom-api` → повторите оплату **99₽** реальной картой или СБП.

---

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| Сразу «активирован» без Робокассы | `PAYMENT_MOCK=true` или пустые ключи в `.env` |
| Оплата прошла, лимит не вырос | Result URL = POST; проверьте Пароль #2; `pm2 logs darom-api --lines 50` |
| Ошибка подписи | Алгоритм **MD5** в кабинете и в коде |
| `relation "payments" does not exist` | Прогнать `migrate_payments.sql` |

---

## API (для справки)

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/api/payments/create` | Создать оплату `{ phone, product_type }` |
| GET | `/api/payments/status?inv_id=` | Статус заказа |
| POST | `/api/payments/robokassa/result` | Callback Робокассы |

`product_type`: `super_donor` | `pickup_pack`
