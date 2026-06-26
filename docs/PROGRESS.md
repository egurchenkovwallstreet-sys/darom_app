# Прогресс «Даром» — файл для нового чата

> **Новый чат Cursor:** напишите  
> `@docs/TZ_DAROM.md` `@docs/PROGRESS.md`  
> и кратко: «продолжаем с этапа X» или «пошли дальше по порядку».

---

## Снимок на 24.06.2026

| | |
|---|---|
| **Текущий этап** | **I — безопасность** ⚠️ **I-A ✅** (токены API); дальше **I-B**; **C — Робокасса** ⏸ |
| **Публичный запуск** | ⏳ **запрещён** до Этапа I + чеклиста (см. ниже) |
| **Сайт** | https://darom-app.online/ |
| **API** | https://darom-app.online/api/health |
| **Backend** | VPS `5.129.243.246`, PM2 `darom-api`, S3 ✅ |
| **Flutter** | Web в продакшене (`git push` → GitHub Actions) + ПК `:8080` |
| **Ядро MVP** | ~**99%** |
| **Полное ТЗ** | ~**73%** |
| **Пользователь** | новичок, нужны **пошаговые** инструкции |
| **Проект** | `C:\Users\User\Desktop\darom_app` |
| **GitHub** | `egurchenkovwallstreet-sys/darom_app` — после изменений **сразу commit + push** |

**Health:** https://darom-app.online/api/health — `ok:true`, `s3Ready:true`, `push.ready:true`, `adminEmail.ready:true`, `vision.mock:false`, `vision.ready:true`.

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
- `git push` → сборка → `/api/deploy-web`

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

### ⚠️ Аудит безопасности (24.06.2026) — ОЧЕНЬ ВАЖНО

**Проверки пользователя (curl + Mozilla Observatory) — подтверждено:**

| Проверка | Результат | Статус |
|----------|-----------|--------|
| `GET /api/users?phone=…` без PIN/токена | Вернулся **полный профиль** (имя, телефон, лимиты…) | 🔴 уязвимость |
| `GET /api/partners/next-code` | Вернулся `{"code":"0007",…}` | 🔴 уязвимость |
| `GET /api/admin/stats/platform` | «Нужен вход в админ-панель» | ✅ OK |
| Mozilla Observatory | Нет HSTS (−20), CSP (−25), X-Frame (−20), nosniff (−5) | 🟡 nginx |

**Полный список уязвимостей и приоритеты:** `docs/TZ_DAROM.md` → **раздел 13**.

**Правило:** публичный запуск **для всех** — только после **Этапа I** и **100% чеклиста** ниже.

---

## 🎯 Следующие шаги (приоритет)

| № | Этап | Задача | Зачем |
|---|------|--------|-------|
| **0** | **I — Безопасность** ← **СЕЙЧАС** | **I-B:** next-code, rate limit, CORS, webhook | Следующий подэтап |
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
- Обновление: `git pull` → миграции (если есть) → `cd backend && npm install` → `pm2 restart darom-api`
- **Важно:** миграции запускать из `/opt/darom_app`, не из `backend/`
- **Деплой сайта:** `git push` → GitHub Actions → API `/api/deploy-web`

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
- **⚠️ Этап I — безопасность** — **критично перед публичным запуском** (см. «План реализации защиты»)
- **Sightengine** — оружие, алкоголь, табак **по картинке**
- **Робокасса** — код ✅; **магазин на одобрении** ⏸
- Роль **moderator**
- **Android / iOS** (этап D)

---

## ⚠️ План реализации защиты (Этап I)

> Пошагово для новичка. Код — через Cursor; сервер — VNC Timeweb.  
> После **каждого подэтапа** — `git commit` + `git push` + на сервере `git pull` + `pm2 restart darom-api`.

### Подэтап I-A — Закрыть утечку данных (P0, ~3–5 дней) ✅ 26.06.2026

| Шаг | Что делаем | Файлы / где | Успех |
|-----|------------|-------------|-------|
| I-A1 | Таблица `user_sessions` (token, user_id, expires_at) | `backend/db/migrate_user_sessions.sql` | ✅ |
| I-A2 | После `login-pin` / `set-pin` — выдать token; middleware проверяет token | `auth.js`, `middleware/user_auth.js` | ✅ |
| I-A3 | Flutter: сохранять token, слать `Authorization: Bearer` | `session_service.dart`, `auth_headers.dart`, все `*_api.dart` | ✅ |
| I-A4 | Все `/api/users`, `/api/chats`, `/api/listings/mine`, favorites… — **только с token** | routes | ✅ |
| I-A5 | Публичные без token: лента, nearby, search, health, auth | routes | ✅ |
| I-A6 | **Проверка curl:** `users?phone=` → **401** | Терминал 2 | ⏳ после деплоя на сервер |

### Подэтап I-B — Быстрые дыры (P0–P1, ~1–2 дня)

| Шаг | Что делаем | Успех |
|-----|------------|-------|
| I-B1 | Удалить или закрыть `GET /api/partners/next-code` (только admin token) | curl → 403 |
| I-B2 | `is_blocked` на всех защищённых маршрутах | Заблокированный не создаёт объявления |
| I-B3 | Rate limit: `login-pin` (5 попыток / 15 мин / IP) | express-rate-limit |
| I-B4 | Rate limit: SMS, admin auth start | Меньше брутфорса |
| I-B5 | CORS: только `https://darom-app.online` + `http://localhost:8080` | `index.js` |
| I-B6 | Webhook Mobile ID: секрет в URL или проверка подписи | Только SMS Aero |

### Подэтап I-C — Сервер и .env (P2, ~0.5 дня, VNC)

| Шаг | Что делаем | Где | Успех |
|-----|------------|-----|-------|
| I-C1 | `.env`: `PAYMENT_MOCK=false`, `ADMIN_EMAIL_MOCK=false`, `SMS_MOCK=false` | `/opt/darom_app/backend/.env` | health ok |
| I-C2 | Проверить: `.env` **не** в GitHub | git | Секреты только на сервере |
| I-C3 | Убрать или усилить `ADMIN_SECRET` (legacy payout) | `admin.js` | Только admin token |
| I-C4 | `pm2 restart darom-api --update-env` | VNC | online |

### Подэтап I-D — nginx заголовки (P3, ~0.5 дня, VNC)

Добавить в `/etc/nginx/sites-available/darom` внутри `server { … }` для HTTPS:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https: blob:; connect-src 'self' https://darom-app.online wss:; font-src 'self' data:;" always;
```

| Шаг | Действие | Успех |
|-----|----------|-------|
| I-D1 | `nginx -t` | syntax is ok |
| I-D2 | `systemctl reload nginx` | без ошибок |
| I-D3 | Observatory → цель **B+** | меньше красных пунктов |

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
- [ ] I-A6: `curl users?phone=` → **401**, не JSON *(проверить после VNC-деплоя)*
- [ ] I-B1: `curl partners/next-code` → **403**
- [ ] I-B3: после 10 неверных PIN — блок / пауза
- [ ] I-B5: CORS не `*`
- [ ] Заблокированный пользователь не может чаты/объявления
- [ ] `curl admin/stats` → «Нужен вход» (как сейчас)

### Сервер
- [ ] I-C1: mock-режимы выключены на боевом `.env`
- [ ] `.env` не в git
- [ ] `pm2 restart` после деплоя

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
- [ ] `git pull` на сервере = последний commit с security fixes

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
- **Деплой backend:** `git pull` + `pm2 restart darom-api` (VNC)

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

1. **⚠️ Этап I — безопасность** ← **СЕЙЧАС (обязательно перед запуском для всех)**
2. **Робокасса** — после одобрения магазина
3. **Sightengine** — оружие/алкоголь/табак на фото ⏳
4. Роль moderator
5. Android / iOS (этап D)

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
- [ ] **I — Безопасность** ⚠️ I-A ✅ (26.06), I-B… ← **критично**
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
