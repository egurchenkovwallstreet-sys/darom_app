# Прогресс «Даром» — файл для нового чата

> **Новый чат Cursor:** напишите  
> `@docs/TZ_DAROM.md` `@docs/PROGRESS.md`  
> и кратко: «продолжаем с этапа X» или «пошли дальше по порядку».

---

## Снимок на 16.06.2026

| | |
|---|---|
| **Текущий этап** | **B — сайт на сервере** (GitHub Actions ✅, партнёры ✅, админка ✅) |
| **Backend** | VPS `5.129.243.246:3000`, PM2 `darom-api`, **S3 ✅** |
| **Flutter** | Сайт https://darom-app.online/ (+ запасной http://5.129.243.246/) + разработка ПК `:8080` |
| **Ядро MVP** | ~**97%** |
| **Полное ТЗ** | ~**55%** |
| **Пользователь** | новичок, нужны **пошаговые** инструкции |
| **Проект** | `C:\Users\User\Desktop\darom_app` |

**Health:** http://5.129.243.246:3000/api/health — `ok:true`, `s3Ready:true`, `bucket:darom-photos`.

**Новый чат:** скопируйте промпт из `docs/NEW_CHAT.md`.

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
- **Вход PIN 4 цифры** + SMS раз в ~35 дней (`pin_setup`, `pin_login`)
- **Клавиатура** не перекрывает поля (`auth_form_scroll.dart`, `KeyboardInsetPadding` — auth, чат, поиск, создание объявления)
- **Защита номера в чате:** предупреждение при отправке телефона в сообщении
- **GitHub Actions:** автодеплой Flutter Web на сервер (`deploy-web.yml`)

### Партнёры / блогеры (реферальная система) ✅
| Функция | Статус |
|---------|--------|
| Кнопка «Я партнёр / блогер» (онбординг, экран телефона) | ✅ |
| Регистрация партнёра: код + телефон + SMS + имя | ✅ |
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
| После кнопки — 2FA (SMS + почта), без повторного ввода телефона | ✅ |
| Вход 2FA: SMS на +79138931428 + код на e.gurchenkov@yandex.ru | ✅ |
| Роль **super_admin** (полный доступ) | ✅ |
| Роль **moderator** (только жалобы/блоки — без монетизации) | ⏳ позже |
| Жалобы на объявления (с контекстом объявления) | ✅ |
| Жалобы на чаты (полная переписка) + кнопка в чате | ✅ |
| Блокировка пользователя/объявления: 1–7 дней или навсегда | ✅ |
| Статистика платформы (день/неделя/месяц/всего) | ✅ super |
| Блогеры: следующий код, выплаты, статистика по периодам | ✅ super |
| Почта SMTP для кодов админа | ⏳ mock (код в логах backend) |

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
| 10 объявлений / **20 у основателя** (первые 1000) | ✅ протестировано |
| «Супер даритель» 99₽/30д (+10) — диалог, тест-активация | ✅ |
| 7 заборов/мес → пакет 99₽ (+10) — диалог, тест-активация | ✅ |
| Бронь 24ч, «Отдал», «Активировать повторно» | ✅ |
| Рейтинг 1–5, жалобы (3→скрытие), стоп-слова | ✅ |
| Уровни дарителя, теневой бан &lt;4.0 | ✅ backend |
| SMS-код через API (тест: `SMS_MOCK=true`) | ✅ |

### Не сделано / нужны ключи
- SMS.ru боевой (`SMS_MOCK=false` + API-ключ)
- Firebase push, Yandex Vision
- **Робокасса** (реальная оплата вместо тест-активации)
- SMTP для кодов админа (сейчас mock — код в логах PM2)
- Роль модератора (отдельные аккаунты без доступа к деньгам)
- Android/iOS

---

## Ключевые бизнес-правила

- **Основатель** (первые 1000): **20 бесплатных активных объявлений** + значок + приоритет в ленте (приоритет в ленте ⏳). Монетизация **как у всех**.
- Обычный пользователь: **10** объявлений бесплатно.
- **Супер даритель:** 99₽/30д → +10 объявлений (диалог, не ошибка).
- **Заборы:** 7/мес → 99₽ за 10; «Активировать повторно» **не** тратит лимит получателя.
- Сделка только после **«Отдал»**; счётчики отдано/забрано **не обнуляются**.

### Партнёры / блогеры
- Коды партнёров: **0001–1000**, по очереди (активен только следующий).
- Реферал по коду блогера: **365 дней** с регистрации, **30%** со всех оплат в этот период.
- Выплата партнёрам **ежемесячно**; сумма «за месяц» обнуляется после выплаты админом.
- «Всего заработано» — накопительная, не обнуляется.

---

## Запуск

### Продакшен (основной режим)
- **API:** http://5.129.243.246:3000 — PM2 на сервере, Docker не нужен на ПК
- **Приложение (этап B+):** https://darom-app.online/ — см. `deploy/DOMAIN_HTTPS.md`
- **Проверка:** http://5.129.243.246:3000/api/health

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

**Новые миграции партнёров (по отдельности):**
```bash
cd /opt/darom_app
cat backend/db/migrate_partners.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_sequential_codes.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_referral_365.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_partner_payout_period.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_pin_auth.sql | docker exec -i darom_db psql -U darom -d darom
cat backend/db/migrate_admin.sql | docker exec -i darom_db psql -U darom -d darom
```

---

## API (основное)

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/api/auth/check-phone` | PIN или SMS |
| POST | `/api/auth/set-pin` | Установка PIN |
| POST | `/api/auth/login-pin` | Вход по PIN |
| POST | `/api/partners/validate-activation-code` | Проверка кода партнёра |
| GET | `/api/partners/stats?phone=` | Статистика партнёра |
| GET | `/api/partners/next-code` | Текущий активный код (0001…) |
| POST | `/api/admin/auth/start` | Начать вход в админку (SMS + email) |
| POST | `/api/admin/auth/verify` | Подтвердить коды, получить token |
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
| POST | `/api/users/super-donor` | Тест: Супер даритель |
| POST | `/api/users/pickup-pack` | Тест: пакет заборов |
| POST | `/api/listings/:id/photos` | Загрузить фото (multipart) |
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
  models/      user, listing, deal_info, ...
backend/
  src/routes/  auth.js, users.js, listings.js, partners.js, admin.js, chats.js, deploy_web.js, ...
  src/utils/   admin_auth.js, admin_stats.js, block_helpers.js, partner_helpers.js, ...
  src/services/ email_service.js
  db/          migrate_admin.sql, migrate_partners.sql, migrate_pin_auth.sql, ...
```

---

## Flow приложения

```
Онбординг → [Я партнёр] или Телефон → PIN / SMS → Имя [код блогера?] → Главная
Партнёр: Регистрация партнёра (код 0001… + телефон) → SMS → Имя → Главная
Профиль партнёра → Статистика партнёра (рефералы, выплаты)
Профиль admin-телефона → «Админ-панель» → SMS + код почты → Жалобы / Статистика / Блогеры
Запасной вход в админку: http://…/admin (тот же 2FA)
Повторный вход: PIN или SMS (раз в ~35 дней)
```

---

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| Красный экран `AppColors` / `AuthGate` | Закрыть все localhost; `flutter clean`; запуск **только** `--web-port=8080` |
| Вход не запоминается | Порт не 8080 |
| `column does not exist` | Прогнать миграции (см. выше) |
| Карта пустая | Перезапустить backend; тестовые объявления привязаны к Москве |
| Браузер не даёт геолокацию | Разрешить «Местоположение» для localhost:8080 |
| `deployWebRouter is not defined` | Исправлено — `require('./routes/deploy_web')` в index.js |
| GitHub Actions красный крестик | Сначала `git pull` + `pm2 restart` на сервере, потом Run workflow |
| `No such file or directory` миграция | Команда из `/opt/darom_app`, не из `backend/` |
| SMS | Тест: синяя полоска с кодом; боевой: `SMS_RU_API_ID` + `SMS_MOCK=false` |

---

## ⏳ Этап B — сайт на сервере

1. ✅ GitHub Actions: `git push` → `/api/deploy-web`
2. ✅ Сайт http://5.129.243.246/
3. 🟡 Домен **darom-app.online** + HTTPS (куплен ✅, настройка DNS/nginx ⏳)

## ⏳ Дальше (приоритет)

1. **Робокасса** — реальная оплата
2. **SMTP** для кодов админа (сейчас mock)
3. **SMS.ru** боевой режим
4. **Firebase** push
5. ~~**Домен + HTTPS**~~ → **darom-app.online** (настройка ⏳)
6. Роль **модератора** (отдельные аккаунты)
7. Android/iOS

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
- [x] PIN, чаты, категории, партнёры ✅
- [x] Админ-панель (2FA, жалобы, блоки, статистика, блогеры) ✅
- [x] Админ из профиля (кнопка только у admin-телефона) ✅
- [ ] B+: Домен + HTTPS
- [ ] 8: Робокасса

---

## Тестовый аккаунт (dev)

- Телефон: `+79138931428`, имя: **Евгений**, статус **основатель** + **super admin**
- В профиле: пункт **«Админ-панель»** → 2FA → кабинет админа
- Для проверки лимитов можно использовать `backend/scripts/seed_listings.js`

---

*Обновляй этот файл после каждого завершённого этапа.*
