# Этап J-E — клиент и контент

> Снимок: 27.06.2026. После деплоя: `security.stage:"J-E"`.

## XSS (чаты и объявления)

| Слой | Защита |
|------|--------|
| **Flutter Web** | `Text()` — не HTML; `flutter_html` **не используется** ✅ |
| **Backend чаты** | Ссылки запрещены; HTML-теги вырезаются; `<script`, `javascript:`, `on*=`, iframe — **400** |
| **Backend объявления** | То же + стоп-слова + запрещённые товары |
| **nginx CSP** | Ограничивает inline-скрипты на странице (Observatory B+) |

Даже если злоумышленник вставит `<script>…</script>` в сообщение — в приложении отобразится **обычный текст**, на сервере теги **удаляются**.

---

## Загрузка фото

| Проверка | Где |
|----------|-----|
| Только **JPG / PNG / WEBP** | magic bytes + MIME |
| **SVG, text/*, application/** | явный отказ |
| Размер ≤ **5 МБ** (env `PHOTO_MAX_MB`) | multer + `validateBasicPhoto` |
| Имя файла | `timestamp-random.ext` — path traversal невозможен |
| S3 | Не публичный; только `/api/photos/…` |
| Vision + OCR | модерация + текст на фото |
| Ответ API фото | `X-Content-Type-Options: nosniff`, `Content-Disposition: inline` |

EXIF не удаляется (метаданные GPS в фото) — **P3** на будущее; для объявлений вещей риск низкий.

---

## Сессия и localStorage

| Правило | Детали |
|---------|--------|
| Токен | `localStorage` на origin (`darom-app.online` или `localhost:8080`) |
| Порт **8080** | Обязателен на ПК — иначе другой origin, вход «не запоминается» |
| Выход | `/api/auth/logout` + очистка localStorage (J-C) |
| Production vs dev | Токен с `:8080` **не** действует на `darom-app.online` (разные origin) ✅ |

---

## Health — без лишнего

`/api/health` больше **не отдаёт имя S3 bucket** (только `s3Ready: true/false`).
