# Промпт для нового чата Cursor — «Даром»

Скопируйте блок ниже в **новый чат** (первое сообщение).

---

```
@docs/TZ_DAROM.md @docs/PROGRESS.md @deploy/README.md @deploy/MOBILE_ID.md

Проект «Даром» — бесплатная передача вещей (Flutter Web + Node.js + PostgreSQL + PostGIS).

Я НЕ программист — нужны пошаговые инструкции: что открыть, куда нажать, что должно получиться.
Терминалы называй «Терминал 1» и «Терминал 2». После изменений в коде — сразу commit + push на GitHub.

═══════════════════════════════════════
СНИМОК НА 22.06.2026
═══════════════════════════════════════

Сайт:     https://darom-app.online/
API:      https://darom-app.online/api/health  (ok:true, s3Ready:true)
Запасной: http://5.129.243.246/
Репо:     github.com/egurchenkovwallstreet-sys/darom_app
Путь ПК:  C:\Users\User\Desktop\darom_app
Сервер:   Timeweb VPS 5.129.243.246, /opt/darom_app, PM2 darom-api, Docker darom_db (порт 5433)
Этап:     C — монетизация (ядро MVP ~99%, полное ТЗ ~65%)

═══════════════════════════════════════
ЧТО УЖЕ СДЕЛАНО
═══════════════════════════════════════

Инфраструктура:
- Flutter Web на сервере (GitHub Actions → /api/deploy-web)
- HTTPS darom-app.online, nginx прокси /api/
- Backend PM2, PostgreSQL+PostGIS, фото Yandex S3

Приложение:
- Midnight Glow UI, онбординг, карта OSM, лента, чаты, избранное, профиль
- PIN-авторизация; регистрация БЕЗ SMS (номер → имя → PIN)
- Mobile ID (~3–6 ₽) один раз: первое объявление ИЛИ первое сообщение в чате
- Партнёры: коды 0001–1000, Mobile ID при регистрации, 30% с оплат реферала 365 дней
- Лимиты: 10 объявлений (20 у основателя), Супер даритель 99₽/+10/30д
- Заборы: 7/мес (3/мес при ≥20k объявлений) → 149→299→499₽ за +10
- Фото объявлений через S3 + API; nginx location ^~ /api/ (иначе JPG = 404)
- Публичная оферта с тарифами (lib/data/public_offer.dart, /offer)
- Быстрая анимация ленты объявлений

Админ-панель (/admin или Профиль → Админ-панель):
- 2FA: Mobile ID (~3–6 ₽) + код с почты (SMTP пока mock → pm2 logs)
- Жалобы, блоки, статистика, блогеры, выплаты партнёрам
- Admin-телефон: +79138931428 (Евгений, super_admin, основатель)

═══════════════════════════════════════
СЛЕДУЮЩИЕ ШАГИ (по приоритету)
═══════════════════════════════════════

1. Робокасса ⏸ — код готов, магазин на одобрении (deploy/ROBOKASSA.md)
2. SMTP ← СЕЙЧАС — код админа на e.gurchenkov@yandex.ru (не pm2 logs)
3. Firebase push — бронь, чаты, «Отдал»
4. Yandex Vision — модерация фото
5. Приоритет основателя в сортировке ленты
6. Роль moderator в админке (без доступа к деньгам)
7. Android / iOS (этап D)

═══════════════════════════════════════
ЗАПУСК И ДЕПЛОЙ
═══════════════════════════════════════

ПК (UI, без Docker):
  cd C:\Users\User\Desktop\darom_app
  flutter run -d chrome --web-port=8080
  (порт 8080 обязателен — иначе вход не сохраняется)

Деплой сайта: git push → GitHub Actions → зелёная галочка → Ctrl+F5 на сайте

Деплой backend (VNC на сервере):
  cd /opt/darom_app && git pull
  cat backend/db/migrate_*.sql | docker exec -i darom_db psql -U darom -d darom  (если новые)
  cd backend && npm install && pm2 restart darom-api --update-env

Nginx (фото JPG/PNG — если ещё не делали):
  sed -i 's/location \/api\/ {/location ^~ \/api\/ {/' /etc/nginx/sites-available/darom
  nginx -t && systemctl reload nginx

Миграции Mobile ID (строго по порядку):
  1. migrate_real_phone_verify.sql
  2. migrate_mobile_id.sql
  3. migrate_partner_mobile_id.sql
  4. migrate_admin_mobile_id.sql
  5. migrate_fix_photo_urls.sql

═══════════════════════════════════════
КЛЮЧЕВЫЕ БИЗНЕС-ПРАВИЛА
═══════════════════════════════════════

- Основатель (первые 1000): 20 объявлений, значок; монетизация как у всех
- Супер даритель: 99₽ → +10 объявлений на 30 дней, можно покупать снова
- «Активировать повторно» — лимит заборов НЕ тратится
- Сделка только после «Отдал»; счётчики отдано/забрано не обнуляются
- 3 жалобы → скрытие объявления

═══════════════════════════════════════
.env НА СЕРВЕРЕ (важное)
═══════════════════════════════════════

PUBLIC_BASE_URL=https://darom-app.online
SMS_MOCK=false
SMS_AUTH_MODE=mobile_id
SMS_AERO_EMAIL, SMS_AERO_API_KEY, SMS_AERO_MOBILE_ID_SIGN
DEPLOY_SECRET, WEB_ROOT=/var/www/darom
PAYMENT_MOCK=true (до одобления Робокассы)

═══════════════════════════════════════
ЗАДАЧА
═══════════════════════════════════════

Продолжаем по порядку из «Следующие шаги».
Начни с: [УКАЖИ — например: SMTP для кодов админа]
```

---

## Кратко для себя

| | |
|---|---|
| **Последние коммиты** | Mobile ID админ, оферта, фото+nginx, анимация ленты |
| **Тестовый аккаунт** | +79138931428, Евгений, основатель + super admin |
| **Админка** | Профиль → Админ-панель → Mobile ID + код почты (mock) |
| **Оферта** | Регистрация → «Читать оферту» или `/offer` |
| **GitHub Actions** | Красный крестик → смотреть лог сборки Flutter |
