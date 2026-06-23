# Промпт для нового чата Cursor — «Даром»

Скопируйте **весь блок** ниже в **новый чат** (первое сообщение).

---

```
@docs/TZ_DAROM.md @docs/PROGRESS.md @deploy/README.md @deploy/VISION.md @deploy/ROBOKASSA.md @deploy/MOBILE_ID.md @deploy/SMTP.md @deploy/FIREBASE.md @.cursor/rules/beginner-instructions.mdc @.cursor/rules/darom-project.mdc

Проект «Даром» — бесплатная передача вещей (Flutter Web + Node.js + PostgreSQL + PostGIS).

═══════════════════════════════════════
КТО Я И КАК СО МНОЙ РАБОТАТЬ
═══════════════════════════════════════

Я НЕ программист. Нужны максимально понятные пошаговые инструкции:
• что открыть (браузер, VNC, терминал);
• куда нажать;
• какую команду скопировать целиком;
• что должно появиться на экране = успех;
• что делать, если ошибка.

Терминалы ВСЕГДА называй «Терминал 1» и «Терминал 2».
Не используй жаргон без пояснения (backend = сервер на компьютере, миграция = обновление базы данных).

После ЛЮБЫХ изменений в коде — ОБЯЗАТЕЛЬНО:
1) git add нужные файлы
2) git commit с понятным сообщением
3) git push на GitHub
Без push сайт на сервере не обновится через GitHub Actions.

═══════════════════════════════════════
СНИМОК НА 23.06.2026
═══════════════════════════════════════

Сайт:     https://darom-app.online/
API:      https://darom-app.online/api/health
Запасной: http://5.129.243.246/
Репо:     github.com/egurchenkovwallstreet-sys/darom_app
Путь ПК:  C:\Users\User\Desktop\darom_app
Сервер:   Timeweb VPS 5.129.243.246, /opt/darom_app, PM2 darom-api, Docker darom_db (порт 5433)
Этап:     C — монетизация; F — модерация ✅ (Vision); Sightengine ⏳ (оружие на фото)
Прогресс: ядро MVP ~99% | полное ТЗ ~73%

Health сейчас: ok:true, s3Ready:true, push.ready:true, adminEmail.ready:true, vision.mock:false, vision.ready:true

═══════════════════════════════════════
ЧТО УЖЕ СДЕЛАНО (кратко)
═══════════════════════════════════════

Инфраструктура:
- Flutter Web на сервере (/var/www/darom), GitHub Actions → POST /api/deploy-web
- HTTPS darom-app.online, nginx прокси /api/ (location ^~ /api/ — обязательно для фото JPG)
- Backend PM2, PostgreSQL+PostGIS, фото Yandex S3 (бакет darom-photos)

Приложение:
- Midnight Glow UI, онбординг, карта OSM, лента, чаты, избранное, профиль
- PIN: регистрация БЕЗ SMS (номер → имя → PIN); вход только PIN
- Mobile ID (~3–6 ₽) один раз: первое объявление ИЛИ первое сообщение в чате
- Партнёры: коды 0001–1000, 30% с оплат реферала 365 дней
- Лимиты: 10 объявлений (20 у основателя), Супер даритель 99₽/+10/30д
- Заборы: 7/мес (3/мес при ≥20k объявлений) → 149→299→499₽ за +10
- Публичная оферта: раздел 10.8 — правила модерации и запрещённые категории

Модерация (23.06.2026):
- Стоп-слова: коммерция, цены, ссылки, мессенджеры, Avito/Ozon (stop_words.js)
- Запрещённые товары в тексте: лекарства, алкоголь, табак, оружие, наркотики и др. (prohibited_goods.js)
- Yandex Vision ✅: moderation + OCR на фото (~0,1–0,5 ₽/фото, deploy/VISION.md)
- Sightengine ⏳: оружие/алкоголь/табак на фото — подключим позже (Free 2 000 фото/мес)
- 3 жалобы → скрытие объявления; теневой бан при рейтинге <4.0
- Правила модерации отправлены в поддержку Робокассы + в оферте п. 10.8

Админ-панель (Профиль → Админ-панель или /admin):
- 2FA: Mobile ID + код на e.gurchenkov@yandex.ru ✅
- Push Firebase ✅ (бронь, чат, «Отдал») — darom-6509d
- Жалобы, блоки, статистика, блогеры, выплаты
- Admin-телефон: +79138931428 (Евгений, super_admin, основатель)

═══════════════════════════════════════
СЛЕДУЮЩИЕ ШАГИ (строго по порядку)
═══════════════════════════════════════

1. Робокасса ⏸ ← СЕЙЧАС
   - Код ✅; магазин на одобрении в кабинете
   - Правила модерации уже отправлены в поддержку
   - После одобления: PAYMENT_MOCK=false, тест оплаты 99₽
   - deploy/ROBOKASSA.md

2. Sightengine ⏳ — оружие на фото (после Робокассы или по приоритету)

3. Yandex Vision ✅ (23.06.2026, deploy/VISION.md)

4. Приоритет основателя в сортировке ленты (значок уже есть)

4. Роль moderator в админке (без доступа к деньгам и статистике)

5. Android / iOS — этап D

═══════════════════════════════════════
ЗАПУСК И ДЕПЛОЙ (шпаргалка)
═══════════════════════════════════════

Терминал 2 — ПК (разработка UI, API идёт на Timeweb):
  cd C:\Users\User\Desktop\darom_app
  flutter run -d chrome --web-port=8080
  ⚠️ Порт 8080 ОБЯЗАТЕЛЕН — иначе вход не сохраняется!

Деплой САЙТА (оферта, UI) после git push:
  GitHub → Actions → Deploy Flutter Web → Run workflow (или push в main)
  Ждать зелёную галочку 5–10 мин → Ctrl+F5 на https://darom-app.online/

Деплой BACKEND (сервер, VNC) — Терминал 1:
  docker start darom_db
  cd /opt/darom_app && git pull
  cat backend/db/ИМЯ_МИГРАЦИИ.sql | docker exec -i darom_db psql -U darom -d darom
  cd backend && npm install && pm2 restart darom-api --update-env
  pm2 logs darom-api --lines 20

Nginx (фото — если JPG не открываются):
  sed -i 's/location \/api\/ {/location ^~ \/api\/ {/' /etc/nginx/sites-available/darom
  nginx -t && systemctl reload nginx

Mobile ID миграции (строго по порядку, из /opt/darom_app):
  1. migrate_real_phone_verify.sql
  2. migrate_mobile_id.sql
  3. migrate_partner_mobile_id.sql
  4. migrate_admin_mobile_id.sql

═══════════════════════════════════════
КЛЮЧЕВЫЕ БИЗНЕС-ПРАВИЛА
═══════════════════════════════════════

- «Даром» = только БЕСПЛАТНАЯ передача вещей; продажа запрещена
- Основатель (первые 1000): 20 объявлений, значок; монетизация как у всех
- Супер даритель: 99₽ → +10 объявлений на 30 дней, можно покупать снова
- «Активировать повторно» — лимит заборов НЕ тратится
- Сделка только после «Отдал»; счётчики не обнуляются
- 3 жалобы от разных пользователей → объявление скрыто
- Запрещены: лекарства, алкоголь, табак, оружие, наркотики, пиротехника и др. (оферта 10.8)

═══════════════════════════════════════
.env НА СЕРВЕРЕ (/opt/darom_app/backend/.env)
═══════════════════════════════════════

PUBLIC_BASE_URL=https://darom-app.online
SMS_MOCK=false
SMS_AUTH_MODE=mobile_id
SMS_AERO_EMAIL, SMS_AERO_API_KEY, SMS_AERO_MOBILE_ID_SIGN
PUSH_MOCK=false
FIREBASE_* (настроено)
ADMIN_EMAIL_MOCK=false, SMTP_* (настроено)
DEPLOY_SECRET, WEB_ROOT=/var/www/darom
PAYMENT_MOCK=true  (до одобления Робокассы)
PHOTO_MOCK_MODERATION=false  ✅
YC_VISION_API_KEY=  (настроено на сервере)
YC_FOLDER_ID=b1gnk6agd6fsq1lo2dbj

═══════════════════════════════════════
ЗАДАЧА В ЭТОМ ЧАТЕ
═══════════════════════════════════════

Продолжаем по порядку из «Следующие шаги».
Начни с: [УКАЖИ — например: «Дождаться одобрения Робокассы» или «Приоритет основателя в ленте»]

После каждого этапа обновляй docs/PROGRESS.md и docs/TZ_DAROM.md, затем commit + push.
```

---

## Кратко для себя

| | |
|---|---|
| **Последние коммиты** | `f1178e9` оферта 10.8; `5ca805c` Vision код; `0e14dbc` запрещённые товары |
| **Тестовый аккаунт** | +79138931428, Евгений, основатель + super admin |
| **Админка** | Профиль → Админ-панель → Mobile ID + код на почту |
| **Оферта** | `/offer` — раздел **10.8** правила модерации |
| **Vision** | ✅ сервер; платный ~0,1–0,5 ₽/фото |
| **Sightengine** | ⏳ оружие на фото — позже |
| **Робокасса** | Ждём одобрение; правила модерации отправлены |
| **GitHub Actions** | Красный крестик → открыть лог → Re-run workflow |

## Если сервер «упал»

**Терминал 1 (VNC):**
```bash
docker start darom_db
cd /opt/darom_app && git pull
cd backend && npm install && pm2 restart darom-api --update-env
systemctl start nginx
curl -s http://127.0.0.1:3000/api/health
```

**Успех:** `"ok":true` в ответе curl.
