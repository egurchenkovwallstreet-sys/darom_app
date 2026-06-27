# Робокасса — подключение «Даром»

> Пошагово для новичка. Код оплаты **уже в проекте** — нужны настройки в кабинете Робокассы и строки в `backend/.env` на сервере.

## ⚡ Магазин одобрен — быстрый старт

1. **Кабинет Робокассы** → ваш магазин → технические настройки (см. таблицу ниже).
2. **VNC (сервер)** → `nano /opt/darom_app/backend/.env` → пароли + `PAYMENT_MOCK=false`.
3. **Миграция** (если ещё не делали): `migrate_payments.sql`.
4. `pm2 restart darom-api --update-env`
5. **Проверка:** health → `"payment":{"mock":false,"robokassaConfigured":true}`
6. **Тест:** оплата 99₽ с `ROBOKASSA_TEST_MODE=true`, потом `false` для боевых денег.

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

ROBOKASSA_MERCHANT_LOGIN=Darom-app
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
| `ROBOKASSA_FISCAL=true` | Чек 54-ФЗ (`Receipt`) — **обязателен** для облачной кассы Robokassa |
| `ROBOKASSA_RECEIPT_TAX=none` | НДС в чеке: `none`, `vat0`, `vat20` и т.д. (см. docs.robokassa.ru) |

Сохраните: `Ctrl+O`, Enter, `Ctrl+X`.

```bash
cd /opt/darom_app/backend
npm install
pm2 restart darom-api --update-env
pm2 logs darom-api --lines 10
```

**Успех в логах:** `✓ Payments: Робокасса настроена (боевой режим)`.

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

`pm2 restart darom-api --update-env` → повторите оплату **99₽** реальной картой или СБП.

### Проверка health после настройки

**Терминал 2 (PowerShell на ПК):**

```powershell
curl.exe -s "https://darom-app.online/api/health"
```

| `robokassaTestMode`: **false** | Боевой режим. Если **true** при `false` в `.env` — PM2 держит старый кэш: `pm2 restart darom-api --update-env` или обновите backend (`override: true` в dotenv) |

---

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| Сразу «активирован» без Робокассы | `PAYMENT_MOCK=true` или пустые ключи в `.env` |
| Оплата прошла, лимит не вырос | Result URL = POST; проверьте Пароль #2; `pm2 logs darom-api --lines 50` |
| Кнопка «Перейти к оплате» не работает / зависло | Nginx **CSP** `form-action 'self'` блокирует POST на Robokassa — в `deploy/nginx-security-headers.conf` должно быть `form-action 'self' https://auth.robokassa.ru`, затем `sudo nginx -t && sudo systemctl reload nginx` |
| Ошибка **25** | Магазин **не активирован** для боевых платежей — в кабинете статус «Активен», идентификатор **Darom-app** (регистр!) |
| Ошибка **26** | Неверный **MerchantLogin** — в `.env` должно быть `Darom-app` как в кабинете |
| Ошибка **29** | Неверная подпись — проверьте Пароль #1 и алгоритм **MD5** |
| `relation "payments" does not exist` | Прогнать `migrate_payments.sql` |
| `integer and uuid` при миграции payments | `git pull` и снова `migrate_payments.sql` (`user_id` = UUID) |

---

## API (для справки)

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/api/payments/create` | Создать оплату `{ phone, product_type }` → `payment_url` (наш redirect) + `payment_form` |
| GET | `/api/payments/robokassa/go?inv_id=&token=` | HTML POST-форма на Robokassa (Receipt) |
| GET | `/api/payments/status?inv_id=` | Статус заказа |
| POST | `/api/payments/robokassa/result` | Callback Робокассы |

`product_type`: `super_donor` | `pickup_pack`
