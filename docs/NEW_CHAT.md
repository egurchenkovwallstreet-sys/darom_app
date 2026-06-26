# Промпт для нового чата Cursor — «Даром»

Скопируйте **весь блок** ниже в **новый чат** (первое сообщение).

---

```
@docs/TZ_DAROM.md @docs/PROGRESS.md @deploy/README.md @deploy/MOBILE_ID.md @deploy/SMTP.md @deploy/ROBOKASSA.md @.cursor/rules/beginner-instructions.mdc @.cursor/rules/darom-project.mdc

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
Не используй жаргон без пояснения (backend = сервер на компьютере, миграция = обновление базы данных, токен = секретный пропуск после входа).

После ЛЮБЫХ изменений в коде — ты (Cursor) ОБЯЗАН САМ:
1) git add нужные файлы
2) git commit с понятным сообщением
3) git push на GitHub (origin main)
Не спрашивай «отправить на GitHub?» — делай push автоматически после каждого завершённого подэтапа.
Без push сайт на сервере не обновится через GitHub Actions.

После push backend-изменений — напиши мне команды для VNC (git pull + pm2 restart), я выполню сам.

═══════════════════════════════════════
СНИМОК НА 24.06.2026
═══════════════════════════════════════

Сайт:     https://darom-app.online/
API:      https://darom-app.online/api/health
Запасной: http://5.129.243.246/
Репо:     github.com/egurchenkovwallstreet-sys/darom_app
Путь ПК:  C:\Users\User\Desktop\darom_app
Сервер:   Timeweb VPS 5.129.243.246, /opt/darom_app, PM2 darom-api, Docker darom_db (порт 5433)

Текущий этап: **I — БЕЗОПАСНОСТЬ** ⚠️ КРИТИЧНО (перед публичным запуском для всех)
Также: C — Робокасса ⏸ (магазин на одобрении); Sightengine ⏳

Прогресс: ядро MVP ~99% | полное ТЗ ~73%

⚠️ ПРАВИЛО: публичный запуск для ВСЕХ пользователей ЗАПРЕЩЁН, пока не выполнен Этап I и 100% чеклиста в docs/PROGRESS.md (раздел «Чеклист перед запуском для всех»).

Health: ok:true, s3Ready:true, push.ready:true, vision.ready:true

Последние коммиты: 21cdf4d (лимиты 30/заборы), 4b29aaf (основатели), 9565542 (UX лента/карта)

═══════════════════════════════════════
АУДИТ БЕЗОПАСНОСТИ 24.06.2026 (подтверждено curl + Observatory)
═══════════════════════════════════════

🔴 УЯЗВИМО (исправляем в этом чате):
1. API «верит» только номеру телефона — без токена после PIN можно читать чужие данные
   curl "https://darom-app.online/api/users?phone=79138931428" → вернулся полный профиль
2. GET /api/partners/next-code открыт всем → вернул {"code":"0007"}
3. Webhook Mobile ID без проверки подписи
4. PIN 4 цифры, нет rate limit на login-pin
5. Блок пользователя только при login-pin, не на всех действиях
6. CORS Access-Control-Allow-Origin: *
7. nginx: нет HSTS, CSP, X-Frame-Options (Mozilla Observatory)

✅ УЖЕ ЗАКРЫТО (26.06.2026):
• I-A: токены после PIN — curl users?phone= → 401
• I-B: next-code → 403; CORS не *; rate limit PIN/SMS/админ; webhook Mobile ID секрет
• Автодеплой backend: git push → GitHub Actions Deploy Backend
• Вход по PIN в приложении — протестирован ✅

✅ УЖЕ ХОРОШО (раньше):
• curl admin/stats → «Нужен вход в админ-панель»
• Админ: Mobile ID + код с почты; admin token на API
• PIN хранится захешированным (pbkdf2)
• HTTPS + редирект

Полный список: docs/TZ_DAROM.md раздел 13
План по шагам: docs/PROGRESS.md → «План реализации защиты (Этап I)»

═══════════════════════════════════════
ЧТО УЖЕ СДЕЛАНО В ПРИЛОЖЕНИИ (кратко)
═══════════════════════════════════════

- Flutter Web на сервере, GitHub Actions deploy-web
- HTTPS darom-app.online, nginx location ^~ /api/
- PIN: регистрация без SMS; Mobile ID один раз при первом объявлении/чате
- 30 объявлений бесплатно для всех; заборы 5/7 → 3/5 → 2 (реферал блогера +2)
- Основатели: значок + приоритет в ленте (первые 1000)
- Чаты, избранное, карта OSM, модерация Vision + стоп-слова
- Админка 2FA, Firebase push
- Тестовый аккаунт: +79138931428, Евгений, основатель + super_admin

═══════════════════════════════════════
ЗАДАЧА ЭТОГО ЧАТА — ЭТАП I БЕЗОПАСНОСТЬ (продолжение)
═══════════════════════════════════════

I-A ✅ / I-B ✅ / I-C (код) ✅ — 26.06.2026. **Сейчас: I-C на VNC** (`.env`), затем I-D.

─── I-C: Сервер .env (я делаю на VNC — команды ниже) ───
PAYMENT_MOCK=false — только после одобления Робокассы (пока можно true)
Удалить строку ADMIN_SECRET=… из .env
pm2 restart darom-api --update-env

─── I-D: nginx заголовки (команды для VNC — см. PROGRESS I-D) ───
HSTS, X-Frame-Options, nosniff, Referrer-Policy, CSP

─── I-E: Cloudflare + DDoS (инструкция для меня, не код) ───

─── I-F: rate limit общий на API ───

После КАЖДОГО подэтапа:
1. Обновляй docs/PROGRESS.md (галочки в чеклисте)
2. git commit + git push (сам, без вопроса)
3. Напиши мне что проверить curl-командами из TZ §13.4

═══════════════════════════════════════
ПРОВЕРКИ (я выполню в Терминале 2 на ПК)
═══════════════════════════════════════

curl.exe "https://darom-app.online/api/health"
→ ok:true, security.stage:"I-B"

curl.exe "https://darom-app.online/api/users?phone=79138931428"
→ 401 «Нужен вход» (НЕ JSON с профилем)

curl.exe "https://darom-app.online/api/partners/next-code"
→ 403 (НЕ {"code":"0007"})

curl.exe "https://darom-app.online/api/admin/stats/platform?period=day"
→ «Нужен вход в админ-панель»

═══════════════════════════════════════
ЗАПУСК UI НА ПК
═══════════════════════════════════════

Терминал 2:
  cd C:\Users\User\Desktop\darom_app
  flutter run -d chrome --web-port=8080
⚠️ Порт 8080 ОБЯЗАТЕЛЕН — иначе вход не сохраняется!

═══════════════════════════════════════
ДЕПЛОЙ BACKEND — автоматически через git push (GitHub Actions).
Запасной вариант на VNC (если Actions не сработал):
  cd /opt/darom_app && git fetch origin && git reset --hard origin/main
  cd backend && npm install && pm2 restart darom-api --update-env

═══════════════════════════════════════
НАЧНИ СЕЙЧАС
═══════════════════════════════════════

1. Прочитай docs/TZ_DAROM.md §13 и docs/PROGRESS.md «План реализации защиты»
2. Продолжи с подэтапа I-C (команды VNC для .env)
3. commit + push на GitHub
4. Дай curl-команды для проверки

Не делай Sightengine, Робокассу и Android — только безопасность (Этап I).
```

---

## Кратко для себя

| | |
|---|---|
| **Этап** | **I — безопасность** (I-C VNC → I-D) |
| **Первый шаг** | I-C: `.env` на VNC + проверка health |
| **Проверки** | 3 curl из блока выше |
| **Cursor** | commit + push сам после каждого подэтапа |
| **VNC** | git pull + миграция + pm2 restart — вы сами |
