# Этап J-A — инвентаризация API и карта рисков

> Снимок: 27.06.2026. После деплоя J-B: `GET /api/health` → `security.stage:"J-B"`.

## Легенда

| Auth | Значение |
|------|----------|
| **Нет** | Публичный endpoint |
| **Bearer** | `Authorization: Bearer` — сессия после PIN (`user_sessions`) |
| **Admin** | Admin token после Mobile ID + email |
| **Deploy** | Заголовок `X-Deploy-Secret` (= GitHub Actions) |
| **Webhook** | Секрет в URL (`MOBILE_ID_WEBHOOK_SECRET`) |

| IDOR | Риск подмены id/phone/chatId/listingId |
|------|----------------------------------------|
| ✅ | Защита есть (session + проверка владельца) |
| ⚠️ | Частичная / осознанный компромисс |
| 🔴 | Дыра (исправить) |

---

## Корень и служебные

| Метод | Путь | Auth | Данные | IDOR | Статус |
|-------|------|------|--------|------|--------|
| GET | `/` | Нет | Подсказки API | — | ✅ OK |
| GET | `/api/health` | Нет | Статус сервиса, stage, mock-флаги, **имя S3 bucket** | — | ⚠️ P3: bucket в ответе |
| GET | `/api/config/firebase` | Нет | Публичные ключи FCM (не секреты) | — | ✅ по дизайну |

## Deploy (GitHub Actions → VPS)

| Метод | Путь | Auth | Кто может | Статус |
|-------|------|------|-----------|--------|
| POST | `/api/deploy-web` | Deploy | Только `DEPLOY_SECRET` в GitHub Secrets | ✅ |
| POST | `/api/deploy-backend` | Deploy | Только `DEPLOY_SECRET` | ✅ |

## Auth — вход и регистрация

| Метод | Путь | Auth | Данные | IDOR | Статус |
|-------|------|------|--------|------|--------|
| POST | `/api/auth/check-phone` | Нет + rate 30/15m | registered, has_pin (**без user_name**) | phone | ✅ J-C |
| POST | `/api/auth/logout` | Bearer | отзыв текущей сессии | — | ✅ J-C |
| POST | `/api/auth/logout-all` | Bearer | все сессии кроме текущей | — | ✅ J-C |
| POST | `/api/auth/send-code` | Нет + rate | SMS-код | phone в body | ✅ rate 10/15 мин |
| POST | `/api/auth/verify-code` | Нет | verification_token | phone | ✅ TTL token |
| POST | `/api/auth/set-pin` | Нет | session_token | verification_token | ⚠️ P1 squatting* |
| POST | `/api/auth/login-pin` | Нет + rate | session_token | phone | ✅ rate 5/15 мин |
| POST | `/api/auth/active-verify/send` | **Bearer** | Mobile ID / SMS | phone = session | ✅ J-B |
| GET | `/api/auth/active-verify/poll` | **Bearer** | статус Mobile ID | phone + session_token | ✅ J-B |
| POST | `/api/auth/active-verify/complete` | **Bearer** | подтверждение номера | phone + session_token | ✅ J-B |
| POST | `/api/auth/active-verify/confirm` | **Bearer** | OTP / SMS | phone + session_token | ✅ J-B |
| POST | `/api/auth/partner-verify/*` | Нет | регистрация партнёра | phone (до аккаунта) | ✅ по дизайну |
| POST | `/api/auth/mobile-id/webhook` | Webhook | обновление status | aero id | ✅ I-B |

\* *P1 squatting:* `POST /api/users` без auth + `verification_token` → `set-pin` — осознанный компромисс ТЗ (регистрация без SMS). Сброс через SMS `reset_pin`.

## Users

| Метод | Путь | Auth | Данные | IDOR | Статус |
|-------|------|------|--------|------|--------|
| POST | `/api/users` | Нет | регистрация / имя | phone | ⚠️ P1 squatting |
| GET | `/api/users?phone=` | Bearer | полный профиль + phone | rejectMismatchedPhone | ✅ I-A |
| POST | `/api/users/super-donor` | Bearer | mock-оплата | phone | ✅ только PAYMENT_MOCK |
| POST | `/api/users/pickup-pack` | Bearer | mock-оплата | phone | ✅ |
| POST | `/api/users/avatar` | Bearer | аватар | phone + user id | ✅ |
| POST | `/api/users/push-token` | Bearer | FCM token | phone | ✅ |

## Listings (лента — публичная)

| Метод | Путь | Auth | Данные | IDOR | Статус |
|-------|------|------|--------|------|--------|
| GET | `/api/listings` | Нет | лента (без телефонов) | — | ✅ |
| GET | `/api/listings/nearby` | Нет | карта | — | ✅ |
| GET | `/api/listings/search` | Нет | поиск | — | ✅ |
| GET | `/api/listings/subcategory-counts` | Нет | счётчики | — | ✅ |
| GET | `/api/listings/mine` | Bearer | мои объявления | phone | ✅ |
| POST | `/api/listings` | Bearer | создать | phone + owner | ✅ |
| PATCH | `/api/listings/:id` | Bearer | редактировать | owner_id | ✅ |
| POST | `/api/listings/:id/*` | Bearer | reserve/give/… | owner/participant | ✅ |

## Chats, favorites, deals

| Метод | Путь | Auth | IDOR | Статус |
|-------|------|------|------|--------|
| ALL | `/api/chats/*` | Bearer (router.use) | phone + conversation participant | ✅ |
| ALL | `/api/favorites/*` | Bearer | phone + user_id | ✅ |
| POST | `/api/deals/:id/rate` | Bearer | deal participant | ✅ |

## Partners

| Метод | Путь | Auth | IDOR | Статус |
|-------|------|------|------|--------|
| POST | `/api/partners/validate-activation-code` | Нет | перебор кодов | ⚠️ P2 |
| GET | `/api/partners/next-code` | Нет | — | ✅ 403 I-B |
| GET | `/api/partners/stats` | Bearer | phone + is_partner | ✅ |

## Payments

| Метод | Путь | Auth | IDOR | Статус |
|-------|------|------|------|--------|
| POST | `/api/payments/create` | Bearer | phone + user_id | ✅ |
| GET | `/api/payments/status` | Bearer | **user_id = session** | ✅ J-B |
| POST | `/api/payments/robokassa/result` | Подпись MD5 | inv_id + сумма | ✅ |
| GET | `/api/payments/robokassa/success\|fail` | Нет | redirect | ✅ |

## Admin

| Метод | Путь | Auth | Статус |
|-------|------|------|--------|
| POST | `/api/admin/auth/*` | Нет + rate | ✅ Mobile ID + email |
| GET/POST | `/api/admin/*` (кроме auth) | Admin token | ✅ super_admin где нужно |

## Photos

| Метод | Путь | Auth | Статус |
|-------|------|------|--------|
| GET | `/api/photos/listings/:fileName` | Нет | ✅ имя = timestamp+random, regex |
| GET | `/api/photos/avatars/:fileName` | Нет | ✅ |

## Flutter Web — хранение токена

| Что | Где | Риск |
|-----|-----|------|
| `session_token` | localStorage (`session_storage_web.dart`) | XSS → кража сессии; CSP nginx снижает |
| phone, name, userId | localStorage | не секрет |
| Admin token | отдельный ключ admin session | то же |

Порт **8080** обязателен — иначе origin/localStorage другой.

## Секреты (не в git)

| Секрет | Где | В git? |
|--------|-----|--------|
| `DEPLOY_SECRET` | server `.env` + GitHub Secrets | ❌ |
| `MOBILE_ID_WEBHOOK_SECRET` | server `.env` | ❌ |
| Robokassa password1/2 | server `.env` | ❌ |
| SMS Aero, SMTP, Firebase private key, S3, Vision | server `.env` | ❌ |
| Firebase web keys | `/api/config/firebase` | ✅ публичные |
