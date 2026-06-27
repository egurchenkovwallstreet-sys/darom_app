# Промпт для нового чата Cursor — «Даром»

Скопируйте **весь блок** ниже в **новый чат** (первое сообщение).

---

```
@docs/TZ_DAROM.md @docs/PROGRESS.md @deploy/CLOUDFLARE.md @deploy/NGINX_SECURITY.md @deploy/MOBILE_ID.md @deploy/SMTP.md @deploy/ROBOKASSA.md @deploy/FIREBASE.md @.cursor/rules/beginner-instructions.mdc @.cursor/rules/darom-project.mdc

Проект «Даром» — бесплатная передача вещей (Flutter Web + Node.js + PostgreSQL/PostGIS + Yandex S3).

═══════════════════════════════════════
КТО Я И КАК СО МНОЙ РАБОТАТЬ
═══════════════════════════════════════

Я НЕ программист. Нужны максимально понятные пошаговые инструкции:
• что открыть (браузер, VNC Timeweb, терминал);
• куда нажать;
• какую команду скопировать целиком;
• что должно появиться на экране = успех;
• что делать, если ошибка.

Терминалы ВСЕГДА называй «Терминал 1» и «Терминал 2».
Не используй жаргон без пояснения (backend = сервер, миграция = обновление БД, токен = пропуск после PIN, IDOR = доступ к чужим данным по подмене id).

После ЛЮБЫХ изменений в коде — ты (Cursor) ОБЯЗАН САМ:
1) git add нужные файлы
2) git commit с понятным сообщением
3) git push на GitHub (origin main)
Не спрашивай «отправить на GitHub?» — делай push автоматически после каждого завершённого подэтапа.
Backend деплоится сам: git push (папка backend/) → GitHub Actions «Развертывание бэкенда».
Flutter Web: git push → «Разверните Flutter Web» (workflow_dispatch — запуск вручную в Actions, если нужен деплой UI).

Миграции БД и правки nginx — команды для VNC Timeweb; я выполню сам.

═══════════════════════════════════════
СНИМОК НА 27.06.2026
═══════════════════════════════════════

Сайт:     https://darom-app.online/
API:      https://darom-app.online/api/health
Запасной: http://5.129.243.246/
Репо:     github.com/egurchenkovwallstreet-sys/darom_app
Путь ПК:  C:\Users\User\Desktop\darom_app
Сервер:   Timeweb VPS 5.129.243.246, /opt/darom_app, PM2 darom-api, Docker darom_db (порт 5433)

Прогресс: ядро MVP ~99% | полное ТЗ ~76%

⚠️ ПРАВИЛО: публичный запуск для ВСЕХ пользователей ЗАПРЕЩЁН, пока не выполнен 100% чеклиста в docs/PROGRESS.md (раздел «Чеклист перед запуском для всех») + этап J (глубокий аудит безопасности).

Health (проверено 27.06):
  ok:true, security.stage:"I-F", apiRateLimitMax:400, authRateLimitMax:60
  sms.mock:false, payment.mock:false (или true до одобления Робокассы), vision.ready:true, push.ready:true

DNS: Cloudflare **DNS only** (серое ☁️) → 5.129.243.246; сайт в РФ **без VPN** ✅
DDoS: Timeweb «Защита от DDoS» ✅ + nginx HSTS/CSP + rate limit backend

Последние коммиты:
  094ef55 — rate limit 400/min (было 100 — мало для polling чатов)
  87970e6 — docs этап I
  7738432 — api_config dev → https://darom-app.online

Тестовый аккаунт: +79138931428, Евгений, основатель + super_admin

═══════════════════════════════════════
ЧТО УЖЕ СДЕЛАНО — ЭТАП I (26–27.06) ✅ ЗАКРЫТ
═══════════════════════════════════════

| Подэтап | Результат |
|---------|-----------|
| I-A | Токены после PIN (user_sessions), Bearer на защищённых API; users?phone= → 401 |
| I-B | next-code → 403; CORS whitelist; rate limit PIN/SMS/админ; webhook Mobile ID секрет |
| I-C | Mock выключены на сервере; legacy ADMIN_SECRET убран |
| I-D | nginx HSTS, CSP, X-Frame, nosniff (deploy/nginx-security-headers.conf) |
| I-E | Cloudflare DNS only (НЕ Proxied — иначе в РФ VPN); Timeweb DDoS ✅ |
| I-F | Rate limit API 400/min + auth 60/min (было 100/20) |

Ключевые файлы безопасности:
  backend/src/middleware/user_auth.js, rate_limit.js, mobile_id_webhook.js
  backend/src/security_version.js (stage: I-F)
  lib/services/session_service.dart, auth_headers.dart, api_config.dart
  .github/workflows/deploy-backend.yml

Автодеплой backend: git push backend/** → Deploy Backend → /api/deploy-backend

═══════════════════════════════════════
ЗАДАЧА ЭТОГО ЧАТА — ЭТАП J: ГЛУБОКИЙ АУДИТ БЕЗОПАСНОСТИ
═══════════════════════════════════════

Этап I закрыл известные дыры из аудита 24.06. Сейчас нужен **полный аудит** на:
1) **Утечки данных** — любые способы прочитать чужие профили, чаты, объявления, фото, коды партнёров, админ-данные без прав
2) **Взломы** — обход авторизации, подмена пользователя, эскалация привилегий, брутфорс PIN, подделка webhook/оплаты, XSS в чатах, загрузка вредоносных файлов, SQL-инъекции
3) **Полная утрата доступа и контроля** — сценарии, когда я теряю сайт, домен, сервер, GitHub, БД, админку, секреты; нет бэкапов; один человек = единственная точка отказа

Работай **системно**: сначала инвентаризация всех API и секретов, потом проверки (curl + код), потом исправления по приоритету P0→P3, потом runbook «что делать если…».

### J-A — Инвентаризация и карта атаки
- Пройти все routes в backend/src/routes/*.js
- Таблица: endpoint | auth? | чьи данные | риск IDOR | статус
- Публичные vs защищённые; что принимает phone/userId/listingId/chatId в query/body
- Deploy endpoints (/api/deploy-web, /api/deploy-backend) — кто может вызвать
- Flutter: где хранится token (localStorage), что утекает в логи/ошибки

### J-B — Утечки данных (P0)
Проверить curl и кодом (без токена / с токеном пользователя A → данные пользователя B):
- GET/POST /api/users, /api/chats, /api/listings/mine, /api/favorites, /api/deals
- Чтение чужих объявлений, сообщений, сделок, аватаров, фото (/api/photos/)
- Утечка телефонов в ленте, чатах, API ошибках
- Партнёры: /api/partners/*, админские данные через обычный token
- S3: прямой доступ к bucket vs только через API
- Health и /api/config — не отдают ли лишнее

### J-C — Взлом авторизации и сессий (P0–P1)
- PIN 4 цифры + rate limit 5/15 мин — достаточно ли? нужен ли lockout/account freeze?
- Перебор session token; срок жизни 30 дней; logout/revoke всех сессий
- Подмена phone в query при наличии token другого user
- is_blocked на ВСЕх защищённых маршрутах
- Админка: Mobile ID + email code — нет ли обхода; admin token scope
- CORS + CSRF для state-changing запросов с браузера

### J-D — Webhook, оплата, внешние интеграции (P1)
- Mobile ID webhook без/с неверным секретом
- Робокassa callback — подпись, повтор callback, сумма, userId
- SMS Aero / Firebase / Yandex Vision — ключи только на сервере, не в клиенте
- DEPLOY_SECRET, MOBILE_ID_WEBHOOK_SECRET, JWT если есть — не в git

### J-E — Клиент и контент (P1–P2)
- XSS в тексте объявлений и чатов (отображение в Flutter Web)
- Загрузка фото: MIME, размер, path traversal, SVG/EXIF
- localStorage/session fixation на :8080 vs production

### J-F — Утрата контроля и восстановление (P0 infra)
Составить и проверить чеклист + инструкции для меня:
| Риск | Что проверить / сделать |
|------|-------------------------|
| Потеря доступа к GitHub | 2FA, backup codes, второй maintainer? |
| Потеря VPS Timeweb | пароль, 2FA, rescue, кто ещё имеет доступ |
| Потеря домена Reg.ru | срок, автопродление, 2FA, NS Cloudflare |
| Потеря Cloudflare | 2FA, email recovery |
| Потеря .env / секретов | где хранится backup .env (НЕ в git); ротация ключей |
| Потеря БД | есть ли pg_dump / бэкап Timeweb; как восстановить |
| Потеря админки | super_admin в БД; вход без единственного телефона |
| Компрометация DEPLOY_SECRET | кто может деплоить с GitHub Actions |
| SSL истёк | certbot auto-renew, мониторинг |
| PM2 упал | pm2 startup, health alert |

Итог J-F: документ deploy/DISASTER_RECOVERY.md (или раздел в PROGRESS) — пошагово для новичка.

### J-G — Фиксация и чеклист
- Обновить docs/PROGRESS.md — новый раздел «Этап J» с подэтапами и галочками
- Обновить docs/TZ_DAROM.md §13 — новые находки и статусы
- security_version.js → stage "J-…" по мере закрытия подэтапов
- Регрессия: curl из TZ §13.4 после каждого исправления

═══════════════════════════════════════
НЕ ДЕЛАТЬ В ЭТОМ ЧАТЕ (если не блокирует безопасность)
═══════════════════════════════════════

- Sightengine, Android/iOS магазины
- Робокасса (кроме аудита callback/подписи) — магазин на одобрении
- Новые фичи UI, не связанные с безопасностью

═══════════════════════════════════════
БАЗОВЫЕ ПРОВЕРКИ (я выполню в Терминале 2)
═══════════════════════════════════════

curl.exe -s "https://darom-app.online/api/health"
→ apiRateLimitMax:400, stage:"I-F"

curl.exe "https://darom-app.online/api/users?phone=79138931428"
→ 401 «Нужен вход» (НЕ JSON с профилем)

curl.exe "https://darom-app.online/api/partners/next-code"
→ 403

curl.exe "https://darom-app.online/api/admin/stats/platform?period=day"
→ «Нужен вход в админ-панель»

nslookup darom-app.online 8.8.8.8
→ 5.129.243.246

═══════════════════════════════════════
ЗАПУСК UI НА ПК
═══════════════════════════════════════

Терминал 2:
  cd C:\Users\User\Desktop\darom_app
  flutter run -d chrome --web-port=8080
⚠️ Порт 8080 ОБЯЗАТЕЛЕН — иначе вход не сохраняется!

═══════════════════════════════════════
ДЕПЛОЙ
═══════════════════════════════════════

Backend: git push → GitHub Actions «Развертывание бэкенда»
Запасной VNC:
  cd /opt/darom_app && git fetch origin && git reset --hard origin/main
  cd backend && npm install && pm2 restart darom-api --update-env

Flutter Web: Actions → «Разверните Flutter Web» → Run workflow

═══════════════════════════════════════
НАЧНИ СЕЙЧАС
═══════════════════════════════════════

1. Прочитай docs/PROGRESS.md (этап I) и docs/TZ_DAROM.md §13
2. Сделай J-A: полная таблица всех API endpoints и рисков
3. Выполни J-B: curl-тесты утечек (покажи мне команды для Терминала 2)
4. Составь приоритизированный список находок P0→P3
5. Начни закрывать P0; после каждого подэтапа — commit + push + обновление PROGRESS/TZ
6. Параллельно набросай J-F (утрата контроля) — что мне проверить в панелях Timeweb/Reg.ru/GitHub

Не включай Cloudflare Proxied (оранжевое облако) — ломает доступ из РФ без VPN.
```

---

## Кратко для себя

| | |
|---|---|
| **Этап** | **J — глубокий аудит** (утечки, взломы, утрата контроля) |
| **I** | ✅ закрыт 26–27.06 (I-A…I-F, rate limit 400/min) |
| **Cloudflare** | DNS only (серое ☁️), **не Proxied** |
| **Проверки** | `curl health` → I-F, apiRateLimitMax:400 |
| **Cursor** | commit + push сам после каждого подэтапа |
| **VNC** | миграции, nginx, .env — вы сами |
