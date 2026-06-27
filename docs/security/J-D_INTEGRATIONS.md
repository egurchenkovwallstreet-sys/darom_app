# Этап J-D — webhook, оплата, внешние интеграции

> Снимок: 27.06.2026. После деплоя: `security.stage:"J-D"`.

## Mobile ID webhook

| Проверка | Результат |
|----------|-----------|
| POST без секрета | **403 Forbidden** |
| POST с неверным `?secret=` | **403** |
| Без `MOBILE_ID_WEBHOOK_SECRET` на боевом `.env` | **503** (не принимает) |
| Dev-only без секрета | Только если `SMS_MOCK=true` |

**Терминал 2 (PowerShell):**

```powershell
Invoke-RestMethod -Uri "https://darom-app.online/api/auth/mobile-id/webhook" -Method POST -ContentType "application/json" -Body '{"id":1,"status":1}'
```

**Успех:** ошибка 403 (Forbidden) — подделка не проходит.

---

## Робокасса callback (`POST /api/payments/robokassa/result`)

| Проверка | Статус |
|----------|--------|
| Подпись MD5 (password2) | ✅ `verifyResultSignature` |
| Сумма `OutSum` = `amount_rub` в БД | ✅ иначе `bad amount` + откат pending |
| Повторный callback (уже paid) | ✅ `OK{InvId}` без повторного начисления |
| Гонка двух callback | ✅ atomic `UPDATE … WHERE status='pending'` |
| Ошибка fulfill | ✅ статус возвращается в `pending`, Робокасса может повторить |
| userId | ✅ из записи `payments`, не из параметров callback |

---

## Секреты — только на сервере

| Секрет | Клиент Flutter | Git |
|--------|----------------|-----|
| SMS Aero API | ❌ | ❌ `.gitignore` |
| Yandex S3 / Vision | ❌ | ❌ |
| Firebase **private** key | ❌ | ❌ |
| Firebase **web** keys | ✅ `/api/config/firebase` | ✅ публичные |
| Robokassa password1/2 | ❌ | ❌ |
| DEPLOY_SECRET | ❌ GitHub Secrets | ❌ |
| MOBILE_ID_WEBHOOK_SECRET | ❌ | ❌ |
| SMTP | ❌ | ❌ |

---

## Deploy endpoints

| Endpoint | Защита |
|----------|--------|
| `/api/deploy-web` | `X-Deploy-Secret` |
| `/api/deploy-backend` | `X-Deploy-Secret` |

Без секрета → **403 Forbidden**.
