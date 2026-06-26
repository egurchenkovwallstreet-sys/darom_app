# Прогресс «Даром» — файл для нового чата

> **Новый чат Cursor:** напишите  
> `@docs/TZ_DAROM.md` `@docs/PROGRESS.md`  
> и кратко: «продолжаем с этапа X» или «пошли дальше по порядку».

---

## Снимок на 26.06.2026

| | |
|---|---|
| **Текущий этап** | **I — безопасность** ⚠️ **I-A/B/C ✅**; **следующий: I-D nginx (VNC)**; **C — Робокасса** ⏸ |
| **Публичный запуск** | ⏳ **запрещён** до 100% чеклиста Этапа I (см. ниже) |
| **Сайт** | https://darom-app.online/ |
| **API** | https://darom-app.online/api/health |
| **Backend** | VPS `5.129.243.246`, PM2 `darom-api`, S3 ✅, **автодеплой** GitHub Actions |
| **Flutter** | Web в продакшене (`git push` → GitHub Actions) + ПК `:8080` |
| **Ядро MVP** | ~**99%** |
| **Полное ТЗ** | ~**75%** |
| **Пользователь** | новичок, нужны **пошаговые** инструкции |
| **Проект** | `C:\Users\User\Desktop\darom_app` |
| **GitHub** | `egurchenkovwallstreet-sys/darom_app` — после изменений **сразу commit + push** |

**Health:** https://darom-app.online/api/health — `security.stage:"I-C"`, `sms.mock:false`, `adminEmail.mock:false`, `payment.mock` (зависит от Робокассы).

**Новый чат:** скопируйте промпт из `docs/NEW_CHAT.md`.

---

## 📋 Резюме проделанной работы (16–22.06.2026)

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
| Mozilla Observatory | Нет HSTS, CSP… | ⏳ I-D (nginx) |

**Полный список:** `docs/TZ_DAROM.md` → **раздел 13**.

### Безопасность I-A / I-B + автодеплой backend (26.06.2026) ✅

- **I-A:** токены после PIN (`user_sessions`), Bearer на защищённых API, Flutter `auth_headers.dart`
- **I-B:** закрыт `next-code`, rate limit PIN/SMS/админ, CORS, секрет webhook Mobile ID
- **Деплой backend:** GitHub Actions `Deploy Backend` (`.github/workflows/deploy-backend.yml`) — `git push` → `/api/deploy-backend`
- **Проверка версии на сервере:** `GET /api/health` → `"security":{"stage":"I-B",…}`
- **Один раз bootstrap (VNC):** `git fetch && git reset --hard origin/main` — если сервер отставал от GitHub
- **Вход по PIN:** протестирован в приложении ✅

**Правило:** публичный запуск **для всех** — только после **100% чеклиста** Этапа I.

---

## 🎯 Следующие шаги (приоритет)

| № | Этап | Задача | Зачем |
|---|------|--------|-------|
| **0** | **I — Безопасность** ← **СЕЙЧАС** | **I-D:** nginx HSTS/CSP (`deploy/NGINX_SECURITY.md`); **I-E** Cloudflare | До публичного запуска |
| **1** | **C — Робокасса** | Дождаться одобрения → тест оплаты; `PAYMENT_MOCK=false` | Монетизация |
| **2** | **Sightengine** | Оружие/алкоголь/табак на фото | ⏳ после запуска или по приоритету |
| **3** | Админка | Роль **moderator** | Отдельные модераторы |
| **4** | **D — Магазины** | Android APK / iOS | Нативные приложения |

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
- **Деплой backend (основной):** `git push` → GitHub Actions `Deploy Backend`
- **Запасной (VNC):** `git fetch origin && git reset --hard origin/main` → `cd backend && npm install` → `pm2 restart darom-api --update-env`
- **Миграции:** из `/opt/darom_app` (не из `backend/`)
- **Деплой сайта:** `git push` → GitHub Actions → `/api/deploy-web`

### Backend + БД
- Node.js + Express + PostgreSQL/PostGIS (Docker, порт **5433**)
- API: users, listings, deals, auth, health

### Бизнес-логика (по ТЗ)
| Функция | Статус |
|---------|--------|
| **30** объявлений для всех + «Супер даритель» 99₽/30д (+10) | ✅ |
| Заборы **5/7 → 3/5 → 2** + пакеты **149→299→499₽** | ✅ |
| Бронь 24ч, «Отдал», «Активировать повторно» | ✅ |
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
- **Этап I — осталось:** I-C (mock `.env`), I-D (nginx), I-E (Cloudflare), I-F (общий rate limit) + 100% чеклист
- **Sightengine** — оружие, алкоголь, табак **по картинке**
- **Робокасса** — код ✅; **магазин на одобрении** ⏸
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

### Подэтап I-D — nginx заголовки (P3, ~0.5 дня, VNC) ⏳

**Инструкция:** `deploy/NGINX_SECURITY.md`  
**Файл заголовков:** `deploy/nginx-security-headers.conf`

| Шаг | Действие | Успех |
|-----|----------|-------|
| I-D1 | `git pull` → в блок `listen 443 ssl` добавить `include .../nginx-security-headers.conf` | файл на месте |
| I-D2 | `nginx -t` → `systemctl reload nginx` | syntax is ok |
| I-D3 | `curl -sI https://darom-app.online/` — HSTS, CSP, X-Frame | заголовки видны |
| I-D4 | Сайт: вход, лента, карта, фото | всё работает |
| I-D5 | Observatory → цель **B+** | по желанию |

### Подэтап I-E — DDoS (Infra, ~1 день)

| Шаг | Что делаем | Где |
|-----|------------|-----|
| I-E1 | Reg.ru: DNS → Cloudflare (бесплатный план) | Панель Reg.ru |
| I-E2 | Cloudflare: SSL Full, «Under Attack Mode» при атаке | dash.cloudflare.com |
| I-E3 | Timeweb файрвол: только 80, 443 | Панель Timeweb |
| I-E4 | nginx `limit_req_zone` на `/api/` | nginx config |

### Подэтап I-F — Rate limit в backend (P2)

| Шаг | Что делаем |
|-----|------------|
| I-F1 | `express-rate-limit`: 100 req/min общий, 20/min на auth |
| I-F2 | npm install + deploy |

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
- [x] `curl admin/stats` → «Нужен вход» ✅

### Сервер
- [x] I-C1: mock-режимы выключены на боевом `.env` ✅ (26.06, health + pm2 logs)
- [x] I-C2: `.env` **не** в GitHub ✅
- [x] I-C3: legacy `ADMIN_SECRET` убран из кода ✅ (26.06)
- [x] I-C4: pm2 restart, `darom-api` online ✅ (26.06)
- [x] Автодеплой backend через GitHub Actions ✅

### Инфраструктура
- [ ] I-D3: Observatory B+ или лучше
- [ ] I-E1: Cloudflare подключён (рекомендуется)
- [ ] HTTPS работает, сертификат не истёк

### Бизнес
- [ ] Робокасса: тестовая оплата 99₽ прошла (или сознательно mock до одобрения)
- [ ] Оферта актуальна

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
- **Деплой backend:** `git push` → GitHub Actions `Deploy Backend` (секреты `VPS_HOST`, `DEPLOY_SECRET`)

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

## ⏳ Этап C — монетизация (текущий)

1. ⏸ **Робокасса** — код ✅, `deploy/ROBOKASSA.md`; **ждём одобрение магазина** в кабинете
2. ✅ **SMS Aero** — боевой SMS + Mobile ID (активность + партнёры)
3. ✅ **Mobile ID** — активность + партнёры + **админ** (~3–6 ₽)
4. ✅ **SMTP** — боевой на сервере, код на почту админа ✅
5. ✅ **Firebase push** — боевой, протестировано ✅

## ⏳ Дальше

1. **I-D VNC** — nginx заголовки (`deploy/NGINX_SECURITY.md`)
2. **I-E** — Cloudflare + файрвол Timeweb
3. **I-E** — Cloudflare + файрвол Timeweb
4. **I-F** — общий rate limit API (100 req/min)
5. **100% чеклист** → только тогда публичный запуск для всех
6. **Робокасса** — после одобрения магазина
7. **Sightengine** — оружие/алкоголь/табак на фото
8. Роль moderator → **D** Android / iOS

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
- [x] **I-C (код) — legacy ADMIN_SECRET убран, health sms/payment** ✅ (26.06.2026)
- [ ] **I — Безопасность** ⚠️ I-C VNC + I-D/E/F + чеклист ← **критично перед запуском для всех**
- [ ] F: Sightengine — weapon/alcohol/tobacco на фото ⏳
- [ ] C: Робокасса (код ✅, магазин на одобрении ⏸)
- [ ] D: Android / iOS

---

## Тестовый аккаунт (dev)

- Телефон: `+79138931428`, имя: **Евгений**, статус **основатель** + **super admin**
- В профиле: пункт **«Админ-панель»** → Mobile ID + код с **почты** → кабинет админа
- Для проверки лимитов можно использовать `backend/scripts/seed_listings.js`

---

*Обновляй этот файл после каждого завершённого этапа.*
