# Прогресс «Даром» — файл для нового чата

> **Новый чат Cursor:** напишите  
> `@docs/TZ_DAROM.md` `@docs/PROGRESS.md`  
> и кратко: «продолжаем с этапа X» или «пошли дальше по порядку».

---

## Снимок на 27.06.2026

| | |
|---|---|
| **Текущий этап** | **J — глубокий аудит** ✅ (J-A…J-G); **K — сделка в чате** ✅; I ✅; C ✅ |
| **Публичный запуск** | 🟢 **готов к запуску** (оферта ✅ 27.06; 2FA на панелях — после запуска) |
| **Сайт** | https://darom-app.online/ |
| **API** | https://darom-app.online/api/health |
| **Backend** | VPS `5.129.243.246`, PM2 `darom-api`, S3 ✅; **деплой backend — VNC** (`git pull` + pm2) |
| **Flutter** | Web в продакшене (`git push` → GitHub Actions) + ПК `:8080` |
| **Ядро MVP** | ~**99%** |
| **Полное ТЗ** | ~**82%** |
| **Пользователь** | новичок, нужны **пошаговые** инструкции |
| **Проект** | `C:\Users\User\Desktop\darom_app` |
| **GitHub** | `egurchenkovwallstreet-sys/darom_app` — Flutter: **push**; backend: **VNC** (см. «Запуск») |

**Health:** `security.stage:"J-G"` ✅, `textSanitization:true`, `pinAccountLockout:true`, `dailyDbBackup:true`.  
**DNS:** Cloudflare **DNS only** (серое ☁️) → `5.129.243.246`; сайт **без VPN** в РФ ✅.  
**DDoS:** Timeweb «Защита от DDoS» ✅ + rate limit backend + nginx HSTS.  
**Observatory:** **B+** (80/100) ✅ — CSP −20 из‑за Flutter Web `unsafe-inline` (норма).

**Новый чат:** скопируйте промпт из `docs/NEW_CHAT.md`.

---

## 📋 Резюме 27.06.2026 (этот чат — запуск)

### Этап K — сделка через чат ✅
- Бронь только после переписки (получатель + ответ дарителя)
- Системное сообщение дарителю после брони
- Кнопки «Отдал вещь» / «Активировать повторно» в чате
- Миграция: `migrate_chat_system_messages.sql`

### Подготовка к запуску ✅
- Очистка ленты: **40** тестовых объявлений удалено, **15** аккаунтов сохранены
- **Ежедневный бэкап:** `deploy/scripts/daily_db_backup.sh` — cron **03:00**, хранение **15 дней** (БД + `.env`)
- **J-F / J-G** закрыты: `security.stage:"J-G"`, curl §13.4 пройдены
- **Оферта** проверена владельцем ✅
- **UX:** форма «Новое объявление» — поля не обрезаются над клавиатурой (iPhone)
- **2FA** на панелях — после запуска

---

## 💰 Экономика (ориентир для владельца)

> Упрощённая модель. Не замена бухгалтерии. Курс: ₽.

### Источники дохода
| Продукт | Цена | Кто платит |
|---------|------|------------|
| Супер даритель | **99 ₽** / 30 д (+10 объявлений) | Даритель |
| Пакет заборов 1 | **149 ₽** (+10) | Получатель |
| Пакет заборов 2 | **299 ₽** (+10) | Получатель |
| Пакет заборов 3 | **499 ₽** (+10) | Получатель |

### Постоянные расходы (текущий масштаб, ~15 пользователей)
| Статья | ₽/мес |
|--------|--------|
| VPS Timeweb | **800–1 500** |
| Домен Reg.ru | **~30** (годовой / 12) |
| Cloudflare DNS | **0** (Free) |
| Firebase push | **0** (Free tier) |
| SMTP Yandex | **0** |
| **Итого фикс** | **~1 000–1 600** |

### Переменные расходы (на 1 000 MAU / мес, порядок величины)
| Статья | Допущение | ₽/мес на 1k MAU |
|--------|-----------|-----------------|
| Yandex Vision | 0,5 нов. объявл./MAU × 2 фото × 0,3 ₽ | **~300** |
| Yandex S3 | 1 GB + трафик | **~100–300** |
| Mobile ID | 15% новых × 5 ₽ (разовое, в первый месяц) | **~75** (амортизация) |
| Робокасса | 3,5% от оплат | от оборота |
| Блогеры | 30% с оплат рефералов | 0–40% оборота |

### Сценарии по размеру базы (доход / расход / чистыми в месяц)

**Допущения:** MAU = 35% / 30% / 25% / 20% от регистраций (10k→10M).  
**Конверсия в оплату (низкая → высокая):** Супер даритель 0,3→1% MAU; пакеты заборов 1→3% MAU (средний чек **220 ₽**).  
**Партнёры:** 25% оборота уходит блогерам (среднее).

| Регистраций | MAU | Доход брутто | Расходы* | После Робокассы 3,5% | После блогеров 25% | **Чистый ориентир** |
|-------------|-----|--------------|----------|----------------------|---------------------|---------------------|
| **10 000** | 3 500 | 9…35 тыс | 6…12 тыс | | | **−3…+25 тыс** |
| **100 000** | 30 000 | 90…350 тыс | 35…80 тыс | | | **+40…270 тыс** |
| **1 000 000** | 250 000 | 0,8…3,5 млн | 0,3…1,2 млн | | | **+0,4…2,5 млн** |
| **10 000 000** | 2 000 000 | 7…28 млн | 3…12 млн | | | **+3…20 млн** |

\* VPS + S3 + Vision + Mobile ID + масштабирование (при 1M+ — кластер/отдельная БД).

**Пример расчёта для 10 000 регистраций (средний сценарий):**
- MAU 3 500; платят ~70 человек (~2%): 35 × 99 + 35 × 220 ≈ **11 200 ₽** брутто
- Расходы: VPS 1 200 + Vision 1 000 + S3 400 + прочее ≈ **3 500 ₽**
- Робокасса −390 ₽; блогеры −2 800 ₽ → **~4 500 ₽/мес** чистыми (без налога ИП)

**Вывод:** на **10k** пользователей проект **около нуля или небольшой плюс**; основная экономика раскрывается от **100k+** при сохранении конверсии. Главный рычаг — **платные заборы** (149–499 ₽), не «Супер даритель».

---

### Этап B+ — домен и HTTPS ✅
- Домен **darom-app.online** (Reg.ru), DNS → Timeweb VPS
- Nginx: прокси `/api/` без порта 3000, Let's Encrypt
- `api_config.dart` — API через HTTPS на боевом домене
- Инструкция: `deploy/DOMAIN_HTTPS.md`

### Иконка и брендинг ✅
- Иконка: белая **D** + бирюзовая лента (квадратная, PWA + Android)
- Название приложения: **«Даром»** (вместо `darom_app`)
- `flutter_launcher_icons`, web/manifest, favicon

### Геолокация и карта ✅
- Геолокация на **HTTPS** (раньше была отключена вне localhost)
- Автозапрос местоположения на главной после входа
- **Полноэкранная карта:** кнопки радиуса (1 / 2 / 5 / 10 / Город) прямо на карте
- Кнопка «Повторить» при отказе в геолокации

### Профиль и админка ✅
- **Достижения** = 5 уровней дарителя из ТЗ (серые → цветные при получении)
- **Админка:** исправлены кнопки периода (День/Неделя/Месяц/Всего) — текст виден на всех
- **Чаты:** пустые диалоги (зашёл, но не написал) **не показываются** в списке

### Деплой ✅
- GitHub Actions: таймаут загрузки увеличен до 5 мин
- **Сайт:** `git push` → `Deploy Flutter Web` → `/api/deploy-web`
- **Backend:** `git push` (папка `backend/`) → `Deploy Backend` → `/api/deploy-backend` (26.06)

### Авторизация и SMS (21.06.2026, вечер) ✅
- **Регистрация без SMS:** номер (без маски) → имя → PIN → вход; номер **не проверяется**
- **Повторный вход:** только номер + PIN (4 цифры)
- **Подтверждение реального номера — один раз навсегда:** при **первом объявлении** или **первом сообщении в чате**
- **SMS Aero Mobile ID** (~3,39–5,79 ₽ вместо 46 ₽ на Билайне): push «Подтвердить» или SMS с 4 цифрами (`deploy/MOBILE_ID.md`)
- **Партнёры:** **Mobile ID** при регистрации (~3–6 ₽), не дорогое SMS
- **Админ-панель:** **Mobile ID** (~3–6 ₽) + код с почты (SMTP ✅ `deploy/SMTP.md`); запасной режим — SMS
- Инструкции: `deploy/SMS_AERO.md`, `deploy/MOBILE_ID.md`

### Фото, nginx, UX, оферта (21–22.06.2026) ✅
- **Фото объявлений:** исправлены URL (`localhost` → `darom-app.online`), чтение из S3 через API (`photos.js`), миграция `migrate_fix_photo_urls.sql`
- **Nginx:** `location ^~ /api/` — JPG/PNG фото не отдают 404 (regex статики больше не перехватывает `/api/photos/`)
- **Лента:** ускорена анимация появления карточек при скролле (`listings_feed_screen.dart`)
- **Публичная оферта:** тарифы (бесплатно, 99₽, 149/299/499₽) и условия пользования (`lib/data/public_offer.dart`, экран `/offer`)
- **Админ Mobile ID:** `migrate_admin_mobile_id.sql`, API `/api/admin/auth/mobile-id/*`, экран `admin_login_screen.dart`

### SMTP админ-почты + Firebase push (22.06.2026, вечер) ✅
- **SMTP:** код на **e.gurchenkov@yandex.ru** при входе в админку (порт 587, Yandex); запасной SMS если SMTP недоступен — `deploy/SMTP.md`
- **Firebase push:** проект **darom-6509d**, FCM на сервере + Flutter Web; push при **брони**, **чате**, **«Отдал»** — **протестировано** (iPhone, ярлык на рабочий стол); `deploy/FIREBASE.md`
- **Health:** `push.ready:true`, `adminEmail.ready:true`
- Миграция: `migrate_push_tokens.sql`

### Модерация объявлений + оферта + Vision (23.06.2026) ✅
- **Запрещённые товары (текст):** `backend/src/utils/prohibited_goods.js` — блокировка при создании/редактировании объявления (наркотики, оружие, лекарства, алкоголь, табак, пиротехника и др.)
- **Стоп-слова:** коммерция, цены, ссылки, мессенджеры, Avito/Ozon (`stop_words.js`) — уже было ✅
- **Yandex Vision (код):** `vision_service.js` + `photo_moderation.js` — moderation + OCR на фото объявлений и аватаров; инструкция `deploy/VISION.md`
- **Yandex Vision на сервере ✅ (23.06.2026, вечер):** сервисный аккаунт `darom-vision`, роль `ai.vision.user`, API-ключ `yc.ai.vision.execute`; `.env`: `PHOTO_MOCK_MODERATION=false`, `YC_FOLDER_ID=b1gnk6agd6fsq1lo2dbj`; health: `vision.mock:false`, `vision.ready:true`
- **Ограничение Vision:** не распознаёт **оружие по форме** (только adult/gruesome + текст на фото) — тест с фото пистолета прошёл ⛔
- **Sightengine ⏳ (запланировано):** второй слой — weapon + alcohol + tobacco на фото; Free 2 000 фото/мес, далее ~$29/мес за 10 000; подключим позже
- **Публичная оферта раздел 10.8:** правила модерации, разрешённые/запрещённые категории, автоматические проверки, жалобы, санкции (`lib/data/public_offer.dart`)
- **Робокасса:** подготовлен и отправлен развёрнутый ответ поддержке — правила модерации и запрещённые категории (текст также в оферте п. 10.8)

### Робокасса — боевой режим (27.06.2026) ✅
- Магазин **Darom-app** активен; `PAYMENT_MOCK=false`, `ROBOKASSA_TEST_MODE=false`
- Оплата **POST** + чек **Receipt** (54-ФЗ); nginx CSP `form-action` → `auth.robokassa.ru`
- E-mail в форме: `ROBOKASSA_PAYMENT_EMAIL` (автоподстановка)
- **Протестировано:** Супер даритель **99₽**; пакеты заборов **149/299/499₽** — тот же API
- Инструкция: `deploy/ROBOKASSA.md`

### Сделка через чат — новая логика (27.06.2026) ✅
- **K ✅:** кнопка «Забронировать» только после сообщения получателя **и** ответа дарителя
- После брони — системное сообщение дарителю: *«Вещь забронирована. После передачи обязательно отметьте, что сделка прошла успешно — так вам засчитается отданная вещь в рейтинг»*
- После брони — в чате у дарителя кнопки **«Отдал вещь»** и **«Активировать повторно»** (защита лимита заборов)
- Миграция БД: `backend/db/migrate_chat_system_messages.sql`
- Подробно: `docs/TZ_DAROM.md` → **§7.2**

### Основатели и UX ленты (23.06.2026, этот чат) ✅
- Приоритет **основателя** в сортировке ленты и жёлтая подсветка **всех** объявлений основателей (не только своих)
- Таймер брони без секунд; скролл фото на карточке объявления
- Миграция `migrate_fix_founders.sql` — первые 1000 пользователей по дате регистрации
- Коммиты `9565542`, `4b29aaf` → GitHub

### Новые условия монетизации (23.06.2026) ✅
- **Заборы:** 3 этапа (&lt;20k / 20k–50k / ≥50k); реферал блогера +2 на первых двух этапах
- **Объявления:** **30** бесплатно для всех → «Супер даритель» 99₽ (+10)
- Код: `pickup_limits.js`, `limits.js`, `public_offer.dart`, профиль

### ⚠️ Аудит безопасности (24.06.2026) — исправления 26.06.2026

**Исходный аудит (24.06):**

| Проверка | Было | Сейчас |
|----------|------|--------|
| `GET /api/users?phone=…` без токена | Полный профиль | **401** «Нужен вход» ✅ I-A |
| `GET /api/partners/next-code` | `{"code":"0007"…}` | **403** «Доступ запрещён» ✅ I-B |
| `GET /api/admin/stats/platform` | Закрыто | ✅ без изменений |
| CORS `Access-Control-Allow-Origin: *` | `*` | Только darom-app.online + localhost:8080 ✅ I-B |
| Mozilla Observatory | Нет HSTS, CSP… | HSTS + CSP ✅ I-D |

**Полный список:** `docs/TZ_DAROM.md` → **раздел 13**.

### Безопасность I-A / I-B + автодеплой backend (26.06.2026) ✅

- **I-A:** токены после PIN (`user_sessions`), Bearer на защищённых API, Flutter `auth_headers.dart`
- **I-B:** закрыт `next-code`, rate limit PIN/SMS/админ, CORS, секрет webhook Mobile ID
- **Деплой backend:** GitHub Actions `Deploy Backend` (`.github/workflows/deploy-backend.yml`) — `git push` → `/api/deploy-backend`
- **Проверка версии на сервере:** `GET /api/health` → `"security":{"stage":"I-B",…}`
- **Один раз bootstrap (VNC):** `git fetch && git reset --hard origin/main` — если сервер отставал от GitHub
- **Вход по PIN:** протестирован в приложении ✅

**Правило:** публичный запуск **для всех** — только после **100% чеклиста** (раздел ниже).

### Безопасность I-C … I-F + Cloudflare (26.06.2026) ✅

| Подэтап | Результат |
|---------|-----------|
| **I-C** | Mock выключены на сервере; legacy `ADMIN_SECRET` убран; pm2 online |
| **I-D** | nginx HSTS/CSP (`deploy/nginx-security-headers.conf`); curl + браузер ✅ |
| **I-E** | Cloudflare Free, NS Reg.ru → Cloudflare; **DNS only** (не Proxied — иначе в РФ нужен VPN); Timeweb DDoS ✅ |
| **I-F** | Rate limit 100 req/min + auth 20/min; `security.stage:"I-F"` |

**Cloudflare + Россия (важно):** оранжевое облако (Proxied) — провайдеры РФ с июня 2025 режут Cloudflare → сайт без VPN не открывался. **Решение:** серое облако **DNS only** → трафик на Timeweb; `nslookup darom-app.online 8.8.8.8` → `5.129.243.246`. Инструкция: `deploy/CLOUDFLARE.md`.

**Flutter dev (ПК :8080):** `api_config.dart` — API через `https://darom-app.online`, не `http://IP:3000` (коммит `7738432`).

**Коммиты:** `d76aa88` I-C … `7738432` api_config … **J-B** payment IDOR + active-verify session.

---

## 🔒 Этап J — глубокий аудит безопасности (27.06.2026)

> Полная карта API: `docs/security/J-A_ENDPOINTS.md`  
> Восстановление после сбоев: `deploy/DISASTER_RECOVERY.md`

### J-A — Инвентаризация и карта атаки ✅

| Шаг | Результат |
|-----|-----------|
| J-A1 | Пройдены все routes в `backend/src/routes/*.js` |
| J-A2 | Таблица endpoint / auth / IDOR — `docs/security/J-A_ENDPOINTS.md` |
| J-A3 | Deploy: только `X-Deploy-Secret`; Flutter token в localStorage |
| J-A4 | Секреты: `.env` не в git; Firebase web — публичные ключи через `/api/config` |

### J-B — Утечки данных (P0) ✅ 27.06.2026

| Находка | Было | Исправление |
|---------|------|-------------|
| `GET /api/payments/status?inv_id=` | Любой Bearer мог читать чужой заказ | Проверка `payment.user_id === session.userId` |
| `POST /api/auth/active-verify/*` | Без Bearer — захват аккаунта до verify | `requireUserSession` + `rejectMismatchedPhone` |
| Flutter `auth_api.dart` | active-verify без Bearer | `jsonAuthHeaders()` / `authHeaders()` |

**curl без токена (Терминал 2):** users/chats/mine/favorites → **401** ✅ (проверено 27.06)

### J-C — Auth и сессии ✅ 27.06.2026

| Шаг | Что сделано |
|-----|-------------|
| J-C1 | `check-phone`: rate limit **30 / 15 мин** / IP |
| J-C2 | `check-phone`: **убрано `user_name`** — имя только после login-pin |
| J-C3 | PIN: **5 неверных → блок 15 мин** на аккаунт (`migrate_pin_lockout.sql`) + IP limit 5/15 |
| J-C4 | `POST /api/auth/logout` и `/logout-all` — отзыв токена на сервере |
| J-C5 | Flutter: выход из профиля вызывает `/api/auth/logout` |
| J-C6 | `verify-code` rate limit 15/15 мин; partner validate-code 30/15 мин |
| J-C7 | CSRF: Bearer + CORS whitelist — достаточно для Web (документировано) |

**Один раз на сервере (VNC, Терминал 1):**

```bash
cd /opt/darom_app
cat backend/db/migrate_pin_lockout.sql | docker exec -i darom_db psql -U darom -d darom
git fetch origin && git reset --hard origin/main
cd backend && npm install && pm2 restart darom-api --update-env
```

**Успех:** `curl -s https://darom-app.online/api/health` → `"stage":"J-C"`, `"pinAccountLockout":true`

### J-D — Webhook, оплата, интеграции ✅ 27.06.2026

| Шаг | Результат |
|-----|-----------|
| J-D1 | Mobile ID webhook: без секрета → **403**; без `.env` secret на бою → **503** |
| J-D2 | Робokassa: подпись + сумма + **idempotent claim** (повторный callback без двойного начисления) |
| J-D3 | Секреты только в `backend/.env` / GitHub Secrets — не в Flutter, не в git |
| J-D4 | Документ: `docs/security/J-D_INTEGRATIONS.md` |

### J-E — Клиент и контент ✅ 27.06.2026

| Шаг | Результат |
|-----|-----------|
| J-E1 | XSS: Flutter `Text()`; backend `sanitize_text.js` — чаты + объявления |
| J-E2 | Фото: JPG/PNG/WEBP, magic bytes, nosniff на `/api/photos/` |
| J-E3 | Health: имя S3 bucket убрано из ответа |
| J-E4 | Документ: `docs/security/J-E_CLIENT.md`; Observatory **B+** ✅ |

### J-F … J-G — ✅ 27.06.2026

| Подэтап | Статус | Заметки |
|---------|--------|---------|
| **J-F** Утрата контроля | ✅ | `DISASTER_RECOVERY.md`; pg_dump; cron `daily_db_backup.sh` (03:00, 15 дней) |
| **J-G** Фиксация | ✅ | curl §13.4; `security.stage` → J-G |

**J-F — выполнено:**

- [x] Первый **pg_dump** + бэкап перед очисткой объявлений
- [x] Ежедневный cron `deploy/scripts/daily_db_backup.sh` (БД + `.env`, хранение 15 дней)
- [x] `.env` сохранён на ПК (вручную)
- [ ] GitHub/Timeweb/Reg.ru/Cloudflare: 2FA — проверить по желанию

**J-G — выполнено:**

- [x] Три curl из TZ §13.4 (401 users, 403 partners, 401 admin)
- [x] DNS → `5.129.243.246`
- [x] `security_version.js` → `J-G` (деплой backend VNC)

### Приоритет находок (27.06)

| Приоритет | Находка | Статус |
|-----------|---------|--------|
| 🔴 P0 | Payment status IDOR | ✅ J-B |
| 🔴 P0 | active-verify без сессии | ✅ J-B |
| 🔴 P0 | Robokassa double-callback | ✅ J-D |
| 🟠 P1 | Регистрация без SMS → squatting номера | ⚠️ по ТЗ; сброс PIN через SMS |
| 🟠 P1 | check-phone → user_name (enumeration) | ✅ J-C |
| 🟠 P2 | validate-activation-code перебор | ✅ J-C (rate limit) |
| 🟡 P3 | health → bucket name | ✅ J-E |
| 🔵 Infra | Бэкап pg_dump ежедневно | ✅ J-F (`daily_db_backup.sh`, 15 дней) |

---

## 🎯 Следующие шаги (приоритет)

| № | Этап | Задача | Зачем |
|---|------|--------|-------|
| **1** | **J-F** | 2FA на GitHub/Timeweb/Reg.ru/Cloudflare; первый pg_dump | План восстановления |
| **2** | **J-G** | Финальные curl §13.4; закрыть этап J | Фиксация аудита |
| **3** | **Чеклист** | Оферта актуальна; Робокасса после одобрения | 100% перед запуском |
| **4** | **C — Робокасса** | Тест оплаты 99₽; `PAYMENT_MOCK=false` | Монетизация |
| **5** | **Sightengine** | Оружие/алкоголь/табак на фото | ⏳ после запуска или по приоритету |
| **6** | Админка | Роль **moderator** | Отдельные модераторы |
| **7** | **D — Магазины** | Android APK / iOS | Нативные приложения |

---

## ✅ Сделано и протестировано

### UI + Flutter
- Стиль **Midnight Glow**, онбординг, категории, лента, карточка, профиль
- Web: **всегда** `flutter run -d chrome --web-port=8080`
- Сессия: `AuthGate` + localStorage (порт 8080 обязателен)
- **Избранное**, **чаты** (PostgreSQL), поиск на главной, **аватар**, единая кнопка с **бликом**
- Приложение на ПК → **удалённый API** Timeweb (`api_config.dart`)
- **Непрочитанные чаты:** бейдж в навигации и в списке чатов (polling)
- **Категории:** «Для дома» (мебель по комнатам), «Строй материалы», «Прочее»; единый справочник `lib/data/app_categories.dart`
- **Счётчики объявлений** в подкатегориях (live, polling 2 с)
- **Вход PIN 4 цифры**; **регистрация без SMS** (номер → имя → PIN); **подтверждение номера один раз** при первом объявлении или первом сообщении в чате — **Mobile ID** (`real_phone_verify_dialog.dart`)
- **Клавиатура** не перекрывает поля (`auth_form_scroll.dart`, `KeyboardInsetPadding` — auth, чат, поиск, создание объявления)
- **Защита номера в чате:** предупреждение при отправке телефона в сообщении
- **GitHub Actions:** автодеплой Flutter Web на сервер (`deploy-web.yml`); после правок — **сразу `git push`**
- **Фото объявлений:** S3 + API `/api/photos/listings/`; nginx `^~ /api/` обязателен на сервере
- **Публичная оферта:** `lib/data/public_offer.dart` — тарифы, правила сервиса, **раздел 10.8 — модерация и запрещённые категории**
- **Геолокация HTTPS:** `location_service_web.dart` — запрос на darom-app.online
- **Полноэкранная карта:** радиус на `NearbyMapScreen` (`map_radius_options.dart`)
- **Иконка PWA/Android:** `assets/icon/app_icon.png`, `flutter_launcher_icons`
- **Достижения профиля:** 5 уровней дарителя (`profile_achievements.dart`)
- **Чаты:** в списке только диалоги с ≥1 сообщением (backend)

### Партнёры / блогеры (реферальная система) ✅
| Функция | Статус |
|---------|--------|
| Кнопка «Я партнёр / блогер» (онбординг, экран телефона) | ✅ |
| Регистрация партнёра: код + телефон + **Mobile ID** + имя | ✅ ~3–6 ₽ |
| Коды активации **0001–1000** по очереди (следующий после регистрации предыдущего) | ✅ |
| Публичный код блогера = его номер (0001, 0002…) для рефералов | ✅ |
| Обычный пользователь: опциональный «код блогера» при регистрации | ✅ |
| Заявка на партнёрство: почта **Darom.partner.ru@yandex.ru** (открыть / скопировать) | ✅ |
| Статистика партнёра в профиле | ✅ |
| Реферал привязан **365 дней** с регистрации | ✅ |
| **30%** со **всех оплат** реферала в период 365 дней | ✅ |
| После 365 дней реферал не в статистике, новые оплаты не идут | ✅ |
| Две суммы: **к выплате за месяц** (обнуляется) + **всего заработано** | ✅ |
| API выплаты админом (`POST /api/admin/partner-payout`) | ✅ UI + curl |
| Вкладка «Блогеры» в админке с кнопкой «Оплатить» | ✅ |

### Админ-панель ✅
| Функция | Статус |
|---------|--------|
| URL `/admin` (Flutter Web) | ✅ |
| **Вход из профиля:** кнопка «Админ-панель» только у admin-телефона | ✅ протестировано |
| Автоопределение admin по номеру (`can_access_admin_panel` в API профиля) | ✅ |
| После кнопки — 2FA (Mobile ID + почта), без повторного ввода телефона | ✅ |
| Вход 2FA: **Mobile ID** (~3–6 ₽) + код на e.gurchenkov@yandex.ru | ✅ **протестировано** (письмо на почту) |
| Роль **super_admin** (полный доступ) | ✅ |
| Роль **moderator** (только жалобы/блоки — без монетизации) | ⏳ позже |
| Жалобы на объявления (с контекстом объявления) | ✅ |
| Жалобы на чаты (полная переписка) + кнопка в чате | ✅ |
| Блокировка пользователя/объявления: 1–7 дней или навсегда | ✅ |
| Статистика платформы (день/неделя/месяц/всего) | ✅ super (+ исправлены кнопки периода) |
| Блогеры: следующий код, выплаты, статистика по периодам | ✅ super |
| Почта SMTP для кодов админа | ✅ боевой (Yandex 587) + SMS fallback |

### Сервер Timeweb
- VPS `5.129.243.246`, проект `/opt/darom_app`
- Docker `darom_db`, backend через **PM2** `darom-api`
- **Деплой backend (основной для вас):** VNC → `git pull` → `npm install` → `pm2 restart darom-api --update-env`
- **Деплой сайта (Flutter):** `git push` → GitHub Actions → `/api/deploy-web`
- **GitHub Actions Deploy Backend** — опционально (если `DEPLOY_SECRET` совпадает); иначе только VNC

### Backend + БД
- Node.js + Express + PostgreSQL/PostGIS (Docker, порт **5433**)
- API: users, listings, deals, auth, health

### Бизнес-логика (по ТЗ)
| Функция | Статус |
|---------|--------|
| **30** объявлений для всех + «Супер даритель» 99₽/30д (+10) | ✅ |
| Заборы **5/7 → 3/5 → 2** + пакеты **149→299→499₽** | ✅ |
| Бронь 24ч, «Отдал», «Активировать повторно» (карточка объявления) | ✅ |
| **Сделка через чат** (условия брони, подсказка, кнопки в чате) | ✅ §7.2 |
| Робокасса боевой (99₽ + пакеты заборов) | ✅ 27.06.2026 |
| Рейтинг 1–5, жалобы (3→скрытие), стоп-слова | ✅ |
| Запрещённые товары (текст объявления) | ✅ `prohibited_goods.js` |
| Yandex Vision (фото + OCR) | ✅ сервер; adult/gruesome + текст на фото; **~0,1–0,5 ₽/фото** |
| Sightengine (оружие на фото) | ⏳ запланировано; weapon + alcohol + tobacco |
| Уровни дарителя, теневой бан &lt;4.0 | ✅ backend |
| SMS-код через API | ✅ SMS Aero боевой (`SMS_MOCK=false`) |
| Mobile ID (подтверждение номера при активности) | ✅ ~3–6 ₽/попытка |
| Регистрация обычного пользователя | ✅ без SMS, только PIN |

### Push-уведомления (Firebase) ✅
| Событие | Статус |
|---------|--------|
| Бронь объявления → дарителю | ✅ протестировано |
| Новое сообщение в чате | ✅ протестировано |
| «Отдал» → получателю | ✅ код + сервер |
| Ярлык iPhone: красная цифра на иконке | ⏳ ограничение iOS Web (нормально) |
| Нативное приложение Android/iOS | ⏳ этап D |

### Не сделано / ждём
- **K — сделка в чате** — условия брони, подсказка дарителю, кнопки «Отдал» / «Активировать» в чате ✅
- **J-F / J-G** — disaster recovery + финальная фиксация аудита
- **100% чеклист** — оферта (Observatory ✅)
- **Sightengine** — оружие, алкоголь, табак **по картинке**
- Роль **moderator**
- **Android / iOS** (этап D)

---

## ⚠️ План реализации защиты (Этап I)

> Пошагово для новичка. Код — через Cursor; **деплой backend — автоматически** (`git push` → GitHub Actions).  
> Миграции БД и nginx — **VNC Timeweb**. Проверка: `/api/health` → `security.stage`.

### Подэтап I-A — Закрыть утечку данных (P0, ~3–5 дней) ✅ 26.06.2026

| Шаг | Что делаем | Файлы / где | Успех |
|-----|------------|-------------|-------|
| I-A1 | Таблица `user_sessions` (token, user_id, expires_at) | `backend/db/migrate_user_sessions.sql` | ✅ |
| I-A2 | После `login-pin` / `set-pin` — выдать token; middleware проверяет token | `auth.js`, `middleware/user_auth.js` | ✅ |
| I-A3 | Flutter: сохранять token, слать `Authorization: Bearer` | `session_service.dart`, `auth_headers.dart`, все `*_api.dart` | ✅ |
| I-A4 | Все `/api/users`, `/api/chats`, `/api/listings/mine`, favorites… — **только с token** | routes | ✅ |
| I-A5 | Публичные без token: лента, nearby, search, health, auth | routes | ✅ |
| I-A6 | **Проверка curl:** `users?phone=` → **401** | Терминал 2 | ✅ |

### Подэтап I-B — Быстрые дыры (P0–P1) ✅ 26.06.2026

| Шаг | Что делаем | Успех |
|-----|------------|-------|
| I-B1 | Закрыть `GET /api/partners/next-code` | curl → 403 ✅ |
| I-B2 | `is_blocked` на защищённых маршрутах (middleware I-A) | ✅ |
| I-B3 | Rate limit: `login-pin` (5 / 15 мин / IP) | ✅ |
| I-B4 | Rate limit: SMS, admin auth start | ✅ |
| I-B5 | CORS: `darom-app.online` + `localhost:8080` | ✅ |
| I-B6 | Webhook Mobile ID: секрет в URL (`MOBILE_ID_WEBHOOK_SECRET`) | ✅ |

### Подэтап I-C — Сервер и .env (P2, ~0.5 дня, VNC) ✅ 26.06.2026

| Шаг | Что делаем | Где | Успех |
|-----|------------|-----|-------|
| I-C1 | `.env`: mock выключены | `/opt/darom_app/backend/.env` | ✅ health |
| I-C2 | Проверить: `.env` **не** в GitHub | git | ✅ в `.gitignore` |
| I-C3 | Убрать legacy `ADMIN_SECRET` (выплаты только admin token) | `admin.js` | ✅ код 26.06 |
| I-C4 | Удалить `ADMIN_SECRET` из `.env`; pm2 restart | VNC | ✅ online |

**Команды VNC (Терминал 1 на сервере):**

```bash
cd /opt/darom_app/backend
nano .env
```

Проверьте / измените строки (Ctrl+W — поиск):

```
SMS_MOCK=false
ADMIN_EMAIL_MOCK=false
PUSH_MOCK=false
```

Строку `ADMIN_SECRET=…` — **удалите** (устарела).

`PAYMENT_MOCK=false` — ставьте **только когда Робокасса одобрена**. Пока магазин на одобрении — оставьте `PAYMENT_MOCK=true`.

Сохранить: Ctrl+O → Enter → Ctrl+X. Затем:

```bash
pm2 restart darom-api --update-env
pm2 logs darom-api --lines 15
```

В логах не должно быть «SMS: тестовый режим» и «Admin email: тестовый режим».

### Подэтап I-D — nginx заголовки (P3, ~0.5 дня, VNC) ✅ 26.06.2026

**Инструкция:** `deploy/NGINX_SECURITY.md`  
**Файл заголовков:** `deploy/nginx-security-headers.conf`

| Шаг | Действие | Успех |
|-----|----------|-------|
| I-D1 | `include .../nginx-security-headers.conf` в блок `443 ssl` | ✅ |
| I-D2 | `nginx -t` → `systemctl reload nginx` | ✅ |
| I-D3 | `curl -sI` — HSTS (`Strict-Transport-Security`) | ✅ |
| I-D4 | Сайт: вход, лента, карта | ✅ (26.06, пользователь) |
| I-D5 | Observatory → цель **B+** | ✅ 80/100 (27.06) |

### Подэтап I-E — Cloudflare + DDoS (Infra) ✅ 26.06.2026

**Инструкция:** `deploy/CLOUDFLARE.md`

| Шаг | Что делаем | Успех |
|-----|------------|-------|
| I-E1 | Cloudflare Free + домен `darom-app.online` | ✅ |
| I-E2 | A `@` и `www` → `5.129.243.246`, **DNS only** (серое ☁️) | ✅ (для РФ без VPN) |
| I-E3 | NS Reg.ru → `kira` / `weston`.ns.cloudflare.com | ✅ |
| I-E4 | SSL **Full (strict)** | ✅ |
| I-E5 | Timeweb «Защита от DDoS» включена | ✅ (26.06) |
| I-E6 | Сайт + вход по PIN **без VPN** | ✅ (26.06) |

### Подэтап I-F — Rate limit в backend (P2) ✅ 26.06.2026

| Шаг | Что делаем | Успех |
|-----|------------|-------|
| I-F1 | `express-rate-limit`: 100 req/min общий, 20/min на `/api/auth` | ✅ код |
| I-F2 | `git push` → GitHub Actions Deploy Backend | ✅ |
| I-F3 | `/api/health` → `security.stage:"I-F"`, `apiRateLimit:true` | ✅ |

---

## ✅ Чеклист перед запуском для всех (обязательный)

Отмечать **все** пункты. Запуск для всех **только при 100%**.

### Код и API
- [x] I-A6: `curl users?phone=` → **401**, не JSON ✅
- [x] I-B1: `curl partners/next-code` → **403** ✅
- [x] I-B3: rate limit на `login-pin` (5 / 15 мин) ✅ *(код; при желании проверить 6-й неверный PIN)*
- [x] I-B5: CORS не `*` ✅
- [x] I-B2: `is_blocked` на защищённых маршрутах ✅ *(middleware I-A)*
- [x] I-B6: webhook Mobile ID — секрет в `.env` ✅ *(проверить `MOBILE_ID_WEBHOOK_SECRET` на сервере)*
- [x] I-F1: общий rate limit API (100/min) + auth (20/min) ✅ (26.06)
- [x] I-F3: health `security.stage:"I-F"` на сервере ✅ (26.06)

### Сервер
- [x] I-C1: mock-режимы выключены на боевом `.env` ✅ (26.06, health + pm2 logs)
- [x] I-C2: `.env` **не** в GitHub ✅
- [x] I-C3: legacy `ADMIN_SECRET` убран из кода ✅ (26.06)
- [x] I-C4: pm2 restart, `darom-api` online ✅ (26.06)
- [x] Деплой backend на сервере (VNC `git pull` + pm2) ✅ (27.06)

### Инфраструктура
- [x] I-D2/I-D3: nginx HSTS + заголовки (`Strict-Transport-Security` проверен curl) ✅ (26.06)
- [x] I-D4: сайт в браузере — вход, лента, карта ✅ (26.06)
- [x] I-D5: Observatory **B+** (80/100, 27.06) — CSP −20 из‑за Flutter Web `unsafe-inline` ✅
- [x] I-E1–I-E4: Cloudflare Active, DNS only (серое облако), NS Reg.ru, SSL Full (strict) ✅
- [x] I-E5: Timeweb DDoS включена ✅ (26.06)
- [x] I-E6: сайт **без VPN** в РФ ✅ (26.06)
- [x] HTTPS работает (Let's Encrypt + Cloudflare DNS only) ✅

### Этап J — глубокий аудит (27.06.2026)
- [x] J-B: payment status IDOR закрыт ✅
- [x] J-B: active-verify только с Bearer ✅
- [x] J-C: check-phone без user_name + rate limit ✅
- [x] J-C: PIN lockout 5→15 мин + logout ✅
- [x] J-D: webhook strict + Robokassa idempotent ✅
- [x] J-E: sanitize_text + фото nosniff + health без bucket ✅
- [x] J-E: Observatory B+ ✅
- [x] J-F: чеклист `DISASTER_RECOVERY.md` (pg_dump + cron)
- [x] J-G: финальные curl §13.4 + `security.stage:"J-G"`

### Бизнес
- [x] Робокасса: боевая оплата 99₽ прошла ✅ (27.06.2026)
- [x] Сделка через чат (этап K): условия брони + подсказка + кнопки в чате
- [x] Оферта актуальна ✅ (27.06.2026, проверено владельцем)
- [ ] 2FA GitHub/Timeweb/Reg.ru/Cloudflare — после запуска

### Повторять ежемесячно
- [ ] Три curl из TZ §13.4
- [ ] Observatory
- [ ] `/api/health` → `security.stage` актуален

---

## Ключевые бизнес-правила

- **Основатель** (первые 1000): значок + приоритет в ленте ✅. **30** активных объявлений — как у всех (не 20). Монетизация **как у всех**.
- **Объявления:** **30** бесплатно для всех → «Супер даритель» 99₽/30д → +10 (можно покупать снова). ✅
- **Заборы** (сброс каждый месяц; порог — активные объявления на платформе):
  - **&lt; 20 000:** обычный **5**/мес, реферал блогера **7**/мес
  - **20 000–49 999:** обычный **3**/мес, реферал **5**/мес
  - **≥ 50 000:** **2**/мес для всех
  - Платные пакеты: **149₽** → **299₽** → **499₽** (+10 каждый); после 3-го — блок до нового месяца
  - «Активировать повторно» **не** тратит лимит получателя ✅
- Сделка только после **«Отдал»**; счётчики отдано/забрано **не обнуляются**.
- **Сделка через чат (K, ✅):** бронь после переписки; подсказка дарителю; «Отдал» / «Активировать повторно» **в чате** — см. TZ §7.2.

### Партнёры / блогеры
- Коды партнёров: **0001–1000**, по очереди (активен только следующий).
- Реферал по коду блогера: **365 дней** с регистрации, **30%** со всех оплат в этот период.
- Выплата партнёрам **ежемесячно**; сумма «за месяц» обнуляется после выплаты админом.
- «Всего заработано» — накопительная, не обнуляется.

---

## Запуск

### Продакшен (основной режим)
- **Сайт:** https://darom-app.online/
- **API:** https://darom-app.online/api/health
- **Запасной IP:** http://5.129.243.246/
- **Деплой сайта:** `git push` → GitHub Actions
- **Деплой backend:** VNC (см. «Сервер Timeweb»); GitHub Actions `Deploy Backend` — опционально

### Разработка UI на ПК (пока сайт не выложен)
**Терминал 2 — Flutter** (Docker и backend на ПК **не нужны**):
```powershell
cd C:\Users\User\Desktop\darom_app
flutter run -d chrome --web-port=8080
```
API идёт на Timeweb (`lib/services/api_config.dart`, `remoteHost = 5.129.243.246`).

### Локальный backend (только если отлаживаете server-код)
```powershell
cd C:\Users\User\Desktop\darom_app
docker compose up -d
cd backend
npm run dev
```
В `api_config.dart` временно: `remoteHost = ''`.

---

## Миграции БД

**На ПК (PowerShell), из `C:\Users\User\Desktop\darom_app`:**
```powershell
Get-Content backend\db\migrate_4b.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_super_donor.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_4c.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_4d.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_sms.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_photos.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_listing_extra_packs.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_favorites_chats.sql | docker exec -i darom_db psql -U darom -d darom
Get-Content backend\db\migrate_avatar.sql | docker exec -i darom_db psql -U darom -d darom
```

**На сервере Timeweb (консоль VNC), из `/opt/darom_app`:**

```bash
bash backend/scripts/run_all_migrations.sh
```

**Mobile ID — строго по порядку** (если запускаете вручную):

```bash
cd /opt/darom_app
# 1) поле real_phone_verified_at (если ещё не было)
cat backend/db/migrate_real_phone_verify.sql | docker exec -i darom_db psql -U darom -d darom
# 2) создаёт таблицу mobile_id_sessions — ОБЯЗАТЕЛЬНО первой для Mobile ID
cat backend/db/migrate_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
# 3) доработка для партнёров — только после шага 2
cat backend/db/migrate_partner_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_admin_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_user_sessions.sql | docker exec -i darom_db psql -U darom -d darom
pm2 restart darom-api --update-env
```

**Nginx (фото JPG/PNG) — один раз на сервере:**
```bash
sed -i 's/location \/api\/ {/location ^~ \/api\/ {/' /etc/nginx/sites-available/darom
nginx -t && systemctl reload nginx
```

Если видите `ERROR: relation "mobile_id_sessions" does not exist` — сначала выполните **шаг 2**, потом снова **шаг 3**.

**Новые миграции партнёров (по отдельности):**
```bash
cd /opt/darom_app
cat backend/db/migrate_partners.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_sequential_codes.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_referral_365.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_payout_period.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_pin_auth.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_admin.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_pickup_tiers.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_real_phone_verify.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_mobile_id.sql | docker exec -i darom_db psql -U darom -d darom
```

---

## API (основное)

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/api/auth/check-phone` | PIN или регистрация |
| POST | `/api/auth/set-pin` | Установка PIN |
| POST | `/api/auth/login-pin` | Вход по PIN |
| POST | `/api/auth/active-verify/send` | Подтверждение номера (Mobile ID или SMS) |
| GET | `/api/auth/active-verify/poll` | Статус Mobile ID (push/OTP) |
| POST | `/api/auth/active-verify/complete` | Завершить после push |
| POST | `/api/auth/active-verify/confirm` | Код из SMS (Mobile ID или fallback) |
| POST | `/api/auth/mobile-id/webhook` | Webhook SMS Aero |
| POST | `/api/auth/partner-verify/send` | Mobile ID для регистрации партнёра |
| GET | `/api/auth/partner-verify/poll` | Статус Mobile ID (партнёр) |
| POST | `/api/auth/partner-verify/complete` | Завершить после push (партнёр) |
| POST | `/api/auth/partner-verify/confirm` | Код из SMS (партнёр) |
| POST | `/api/auth/send-code` | SMS: сброс PIN |
| POST | `/api/partners/validate-activation-code` | Проверка кода партнёра |
| GET | `/api/partners/stats?phone=` | Статистика партнёра |
| GET | `/api/partners/next-code` | Текущий активный код (0001…) |
| POST | `/api/admin/auth/start` | Начать вход (Mobile ID + email-код) |
| GET | `/api/admin/auth/mobile-id/poll` | Статус Mobile ID (админ) |
| POST | `/api/admin/auth/mobile-id/complete` | Телефон подтверждён (push) |
| POST | `/api/admin/auth/mobile-id/confirm` | Код OTP (Mobile ID, админ) |
| POST | `/api/admin/auth/verify` | Код с почты + session_token → token |
| GET | `/api/admin/reports/listings` | Жалобы на объявления |
| GET | `/api/admin/reports/chats` | Жалобы на чаты (с перепиской) |
| POST | `/api/admin/block/user` | Блок пользователя |
| POST | `/api/admin/block/listing` | Скрыть объявление |
| GET | `/api/admin/stats/platform?period=` | Статистика (super) |
| GET | `/api/admin/stats/bloggers?period=` | Блогеры (super) |
| POST | `/api/admin/partner-payout` | Выплата партнёру (UI или curl + admin_secret) |
| GET | `/api/admin/partner-codes/status` | Следующий код партнёра |
| POST | `/api/chats/:id/report` | Жалоба на чат |
| POST | `/api/deploy-web` | Деплой Flutter Web (GitHub Actions) |
| GET | `/api/listings/subcategory-counts` | Счётчики в подкатегориях |
| GET | `/api/chats/unread-summary` | Непрочитанные чаты |
| POST/GET | `/api/users` | Регистрация / профиль (`can_access_admin_panel` для admin-телефона) |
| POST | `/api/payments/create` | Создать оплату (Робокасса или mock) |
| GET | `/api/payments/status?inv_id=` | Статус заказа |
| POST | `/api/payments/robokassa/result` | Callback Робокассы |
| POST | `/api/listings/:id/photos` | Загрузить фото (multipart) |
| GET | `/api/photos/listings/:fileName` | Отдать фото (S3 через API) |
| GET/POST | `/api/listings` | Лента / создать |
| GET | `/api/listings/nearby` | Объявления на карте (lat, lng, radius_km) |
| GET | `/api/listings/mine` | Мои объявления |
| POST | `/api/listings/:id/reserve` | Бронь 24ч |
| POST | `/api/listings/:id/give` | Отдал |
| POST | `/api/listings/:id/reactivate` | Активировать повторно |
| POST | `/api/listings/:id/report` | Жалоба |
| POST | `/api/favorites` | Избранное |
| GET/POST | `/api/chats` | Чаты и сообщения |
| POST | `/api/users/avatar` | Аватар |

---

## Структура кода

```
lib/
  screens/     auth_gate, admin_gate, admin_login, admin_dashboard, phone, pin_*, partner_*, profile, ...
  services/    auth_api, admin_api, partners_api, listings_api, users_api, chats_api, ...
  widgets/     midnight_glow_screen, auth_form_scroll, keyboard_inset_padding, ...
  data/        app_categories.dart, public_offer.dart, profile_achievements.dart, ...
  models/      user, listing, deal_info, ...
backend/
  src/routes/  auth.js, users.js, listings.js, partners.js, admin.js, chats.js, deploy_web.js, ...
  src/utils/   admin_auth.js, prohibited_goods.js, stop_words.js, photo_moderation.js, ...
  src/services/ sms_service.js, mobile_id_service.js, email_service.js, vision_service.js, push_service.js
  db/          migrate_admin.sql, migrate_mobile_id.sql, migrate_real_phone_verify.sql, ...
```

---

## Flow приложения

```
Онбординг → Телефон → Имя [код блогера?] → PIN → Главная
  (номер при регистрации НЕ проверяется по SMS)

Партнёр: код 0001… + телефон → Mobile ID (~3–6 ₽) → имя → PIN → Главная

Первое объявление ИЛИ первое сообщение в чате → диалог подтверждения номера
  → Mobile ID (push или SMS ~3–6 ₽) → real_phone_verified навсегда

Повторный вход: только PIN

Профиль admin-телефона → «Админ-панель» → Mobile ID (~3–6 ₽) + код почты (mock) → аналитика

Запасной вход в админку: https://darom-app.online/admin
```

---

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| Красный экран `AppColors` / `AuthGate` | Закрыть все localhost; `flutter clean`; запуск **только** `--web-port=8080` |
| Вход не запоминается | Порт не 8080 |
| `column does not exist` | Прогнать миграции (см. выше) |
| Карта пустая | Перезапустить backend; тестовые объявления привязаны к Москве |
| Браузер не даёт геолокацию | HTTPS ✅; разрешить «Местоположение» для darom-app.online или localhost:8080 |
| Старая иконка на iPhone | Очистить историю Safari → удалить ярлык → добавить на экран заново |
| `deployWebRouter is not defined` | Исправлено — `require('./routes/deploy_web')` в index.js |
| GitHub Actions: timeout deploy | Исправлено — max-time 300 с; Re-run workflow |
| `No such file or directory` миграция | Команда из `/opt/darom_app`, не из `backend/` |
| `relation "mobile_id_sessions" does not exist` | Сначала `migrate_mobile_id.sql`, потом `migrate_partner_mobile_id.sql` (см. раздел «Миграции БД») |
| Фото не показываются (JPG) | Nginx: `location ^~ /api/` + миграция `migrate_fix_photo_urls.sql` |
| GitHub Actions: красный крестик | Открыть лог; часто ошибка Flutter-сборки; Re-run после fix |
| SMS | Боевой: SMS Aero + Mobile ID; `SMS_MOCK=false`, `SMS_AUTH_MODE=mobile_id` на сервере |
| Сайт не открывается **без VPN** (после Cloudflare) | Cloudflare DNS → **DNS only** (серое ☁️), не Proxied; `deploy/CLOUDFLARE.md` |
| «Сервер не отвечает» на ПК `:8080` | API → `https://darom-app.online` (`api_config.dart`); backend на Timeweb, `npm run dev` не нужен |
| `nslookup` без 8.8.8.8 падает, сайт открывается | DNS провайдера глючит; проверка: `nslookup darom-app.online 8.8.8.8` → `5.129.243.246` |

---

## ✅ Этап B — сайт на сервере

1. ✅ GitHub Actions: `git push` → `/api/deploy-web`
2. ✅ Сайт на VPS (IP + домен)

## ✅ Этап B+ — домен + HTTPS

1. ✅ Домен **darom-app.online** (Reg.ru)
2. ✅ DNS → `5.129.243.246`
3. ✅ Nginx + Let's Encrypt
4. ✅ https://darom-app.online/ + API `/api/`
5. ✅ Иконка и название «Даром»

## ✅ Этап C — монетизация ✅ (27.06.2026)

1. ✅ **Робокасса** — боевой режим, 99₽ + пакеты заборов; `deploy/ROBOKASSA.md`
2. ✅ **SMS Aero** — боевой SMS + Mobile ID (активность + партнёры)
3. ✅ **Mobile ID** — активность + партнёры + **админ** (~3–6 ₽)
4. ✅ **SMTP** — боевой на сервере, код на почту админа ✅
5. ✅ **Firebase push** — боевой, протестировано ✅

## ⏳ Дальше

1. **2FA** на панелях (GitHub, Timeweb, Reg.ru, Cloudflare) — после запуска
2. **Sightengine** — оружие/алкоголь/табак на фото
5. Роль moderator → **D** Android / iOS

---

## История этапов

- [x] 1–2: UI, навигация, Midnight Glow
- [x] 3: Backend + PostGIS + Flutter API
- [x] 4A: Профиль, сессия, мои объявления
- [x] 4B: Лимиты объявлений, сделки, Супер даритель
- [x] 4C: Рейтинг, жалобы, уровни, стоп-слова
- [x] 4D: Лимиты заборов, пакет 99₽
- [x] 5: SMS API + тестовый режим (боевой SMS.ru — по желанию)
- [x] 6: Карта — flutter_map + OpenStreetMap (бесплатно, без ключей)
- [x] 7: Фото — Yandex Object Storage ✅ на сервере
- [x] A: Timeweb VPS, PM2, S3 ✅
- [x] B: Flutter Web (GitHub Actions) ✅
- [x] B+: Домен darom-app.online + HTTPS ✅
- [x] B++: Геолокация HTTPS, карта радиус, иконка «Даром», достижения, UX-фиксы (21.06) ✅
- [x] PIN, чаты, категории, партнёры ✅
- [x] Админ-панель (2FA, жалобы, блоки, статистика, блогеры) ✅
- [x] Админ из профиля (кнопка только у admin-телефона) ✅
- [x] SMS Aero + Mobile ID + регистрация без SMS (21.06 вечер) ✅
- [x] Админ: реальное SMS при входе ✅
- [x] Mobile ID для регистрации партнёров ✅
- [x] Фото объявлений + nginx + оферта + UX лента (22.06) ✅
- [x] Админ: Mobile ID при входе ✅
- [x] C: SMTP админ-почты (боевой ✅)
- [x] C: Firebase push (боевой ✅)
- [x] Модерация: запрещённые товары + стоп-слова + оферта 10.8 (23.06) ✅
- [x] Модерация: Yandex Vision — код в backend (23.06) ✅
- [x] C/F: Yandex Vision — на сервере ✅ (23.06.2026)
- [x] Приоритет основателя в ленте + подсветка ✅ (23.06.2026)
- [x] Новые лимиты монетизации (30 объявлений, заборы 5/7→3/5→2) ✅ (23.06.2026)
- [x] **I-A … I-F — Безопасность** ✅ (26.06.2026)
- [x] **J-A … J-E — Глубокий аудит (P0–P3)** ✅ (27.06.2026)
- [x] **J-F … J-G** ✅ (27.06.2026)
- [x] **K — сделка в чате** ✅
- [ ] **100% чеклист** ← перед запуском для всех
- [ ] F: Sightengine — weapon/alcohol/tobacco на фото ⏳
- [x] C: Робокасса ✅ (27.06.2026)
- [ ] D: Android / iOS

---

## Тестовый аккаунт (dev)

- Телефон: `+79138931428`, имя: **Евгений**, статус **основатель** + **super admin**
- В профиле: пункт **«Админ-панель»** → Mobile ID + код с **почты** → кабинет админа
- Для проверки лимитов можно использовать `backend/scripts/seed_listings.js`

---

*Обновляй этот файл после каждого завершённого этапа.*
