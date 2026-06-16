# Прогресс «Даром» — файл для нового чата

> **Новый чат Cursor:** напишите  
> `@docs/TZ_DAROM.md` `@docs/PROGRESS.md`  
> и кратко: «продолжаем с этапа X» или «пошли дальше по порядку».

---

## Снимок на 16.06.2026

| | |
|---|---|
| **Текущий этап** | **A — сервер Timeweb** 🟡 → **B — сайт в интернете** |
| **Backend** | VPS `5.129.243.246:3000`, PM2 `darom-api` |
| **Flutter на ПК** | `remoteHost = 5.129.243.246` в `lib/services/api_config.dart` |
| **Ядро MVP** | ~**92%** |
| **Полное ТЗ** | ~**48%** |
| **Пользователь** | новичок, нужны **пошаговые** инструкции |
| **Проект** | `C:\Users\User\Desktop\darom_app` |

**Health:** http://5.129.243.246:3000/api/health — `ok:true`, `db.connected:true`. На этапе A нужно: `photos.s3Ready:true`.

---

## ✅ Сделано и протестировано

### UI + Flutter
- Стиль **Midnight Glow**, онбординг, категории, лента, карточка, профиль
- Web: **всегда** `flutter run -d chrome --web-port=8080`
- Сессия: `AuthGate` + localStorage (порт 8080 обязателен)
- **Избранное**, **чаты** (PostgreSQL), поиск на главной, **аватар**, единая кнопка с **бликом**
- Приложение на ПК → **удалённый API** Timeweb (`api_config.dart`)

### Сервер Timeweb
- VPS `5.129.243.246`, проект `/opt/darom_app`
- Docker `darom_db`, backend через **PM2** `darom-api`
- Обновление: `git pull` → `cd backend && npm install` → `pm2 restart darom-api`

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
- Firebase, S3/Vision, Робокасса, админка, Android/iOS

---

## Ключевые бизнес-правила

- **Основатель** (первые 1000): **20 бесплатных активных объявлений** + значок + приоритет в ленте (приоритет в ленте ⏳). Монетизация **как у всех**.
- Обычный пользователь: **10** объявлений бесплатно.
- **Супер даритель:** 99₽/30д → +10 объявлений (диалог, не ошибка).
- **Заборы:** 7/мес → 99₽ за 10; «Активировать повторно» **не** тратит лимит получателя.
- Сделка только после **«Отдал»**; счётчики отдано/забрано **не обнуляются**.

---

## Запуск (2 терминала)

**Терминал 1 — Backend:**
```powershell
cd C:\Users\User\Desktop\darom_app
docker compose up -d
cd backend
npm run dev
```
Проверка: http://localhost:3000/api/health

**Терминал 2 — Flutter:**
```powershell
cd C:\Users\User\Desktop\darom_app
flutter run -d chrome --web-port=8080
```

**backend/.env** (важное):
```
PORT=3000
DATABASE_URL=postgresql://darom:darom_dev@127.0.0.1:5433/darom
SMS_RU_API_ID=
SMS_MOCK=true
```

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

---

## API (основное)

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/api/auth/send-code` | Отправить SMS-код |
| POST | `/api/auth/verify-code` | Проверить код |
| POST/GET | `/api/users` | Регистрация / профиль |
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
  screens/     auth_gate, phone, sms, home, listings_feed, listing, profile, ...
  services/    auth_api, listings_api, users_api, deals_api, session_service
  widgets/     midnight_glow_screen, osm_map_widget, super_donor_offer_dialog, ...
  models/      user, listing, deal_info, listing_limit_info, pickup_limit_info
backend/
  src/routes/  auth.js, users.js, listings.js, deals.js
  src/utils/   limits.js, pickup_limits.js, stop_words.js, donor_level.js, ratings.js
  db/          init.sql, migrate_*.sql
```

---

## Flow приложения

```
Онбординг → Телефон → SMS (API, тест-код на экране) → Имя → Главная
  → Категория → Подкатегория → Лента → Карточка (бронь / жалoba / отдал)
  → Профиль | Мои объявления | + Новое объявление
Повторный вход: AuthGate → Главная (localStorage, порт 8080)
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
| `usersRouter is not defined` | Исправлено в `index.js` — перезапустить backend |
| SMS | Тест: синяя полоска с кодом; боевой: `SMS_RU_API_ID` + `SMS_MOCK=false` |

---

## ⏳ Этап A — сервер Timeweb (текущий)

1. **Health OK** — http://5.129.243.246:3000/api/health → `"ok":true`
2. **Миграции** на сервере — `bash backend/scripts/run_all_migrations.sh`
3. **Ключи S3** в `/opt/darom_app/backend/.env` → `photos.s3Ready: true`
4. **git pull** + `pm2 restart darom-api` после push с GitHub
5. **Чеклист в приложении** (Flutter на ПК, порт 8080):
   - регистрация / вход
   - создать объявление **с фото**
   - избранное ❤️
   - написать в чат → забронировать
   - профиль + аватар

## ⏳ Дальше (после этапа A)

1. **Этап B** — Flutter Web на Timeweb + домен/HTTPS
2. **Робокасса** — реальная оплата
3. **Firebase** — push
4. **Админка** → Android/iOS → магазины

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
- [x] 7: Фото — Yandex Object Storage (ключи на сервере ⏳)
- [x] A0: Timeweb VPS, PM2, Flutter → удалённый API
- [ ] **A: Проверка сервера + S3 + чеклист** ← **СЕЙЧАС**
- [ ] B: Flutter Web на сервере
- [ ] 8: Робокасса

---

## Тестовый аккаунт (dev)

- Телефон: `+79138931428`, имя: **Евгений**, статус **основатель**
- Для проверки лимитов можно использовать `backend/scripts/seed_listings.js`

---

*Обновляй этот файл после каждого завершённого этапа.*
