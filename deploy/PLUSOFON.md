# Плюсofon Flash Call — верификация номера в «Даром»

Подтверждение **реального номера** при первом объявлении или первом сообщении в чате (и при регистрации партнёра) через **Flash Call** (~0,6 ₽) вместо SMS Aero Mobile ID (~7 ₽).

Документация API: [help.plusofon.ru/api/v1/flash-call](https://help.plusofon.ru/api/v1/flash-call)

---

## 1. Регистрация в Плюсofon

1. Откройте [plusofon.ru/products/flashcall](https://plusofon.ru/products/flashcall)
2. Нажмите **«Подключить»** или зарегистрируйтесь в [lk.plusofon.ru](https://lk.plusofon.ru)
3. Для ИП/ООО — обычная регистрация; для физлица — через Госуслуги + ЭЦП (см. FAQ на сайте)

**Успех:** вы вошли в личный кабинет Плюсofon.

---

## 2. Подключить Flash Call

1. В кабинете найдите раздел **Flash Call** (или «Авторизация по звонку»)
2. Выберите тариф:
   - **100 звонков — бесплатно** (для теста)
   - **1 000 звонков — 570 ₽/мес** (~0,57 ₽ за звонок)
3. Подключите пакет

**Успех:** в кабинете виден активный пакет Flash Call.

---

## 3. Получить access_token для API

1. В кабинете: **Настройки → API** — включите доступ к API
2. Раздел **Flash Call → Аккаунты** (или через API):
   - создайте аккаунт Flash Call (имя, например `darom`)
   - скопируйте **`access_token`** этого аккаунта

> ⚠️ Нужен именно **access_token аккаунта Flash Call**, не общий токен личного кабинета (для send/check используется access_token аккаунта).

Через API (если есть основной токен кабинета):

```bash
curl -X POST "https://restapi.plusofon.ru/api/v1/flash-call" \
  -H "Content-Type: application/json" \
  -H "Client: 10553" \
  -H "Authorization: Bearer ТОКЕН_ЛИЧНОГО_КАБИНЕТА" \
  -d '{"name":"darom"}'
```

В ответе: `"access_token": "..."` — **его** сохраните.

**Успех:** есть строка `access_token` длиной ~30+ символов.

---

## 4. Тест звонка (PowerShell на ПК)

Подставьте свой `access_token` и номер **без** `+` (например `79138931428`):

```powershell
curl.exe -X POST "https://restapi.plusofon.ru/api/v1/flash-call/send" `
  -H "Content-Type: application/json" `
  -H "Client: 10553" `
  -H "Authorization: Bearer ВАШ_ACCESS_TOKEN" `
  -d "{\"phone\":\"79138931428\"}"
```

**Успех:**
- на телефон приходит **короткий звонок** за ~3 сек;
- в ответе JSON есть `"key": "..."` ;
- последние **4 цифры** номера звонящего — код для проверки.

Проверка кода:

```powershell
curl.exe -X POST "https://restapi.plusofon.ru/api/v1/flash-call/check" `
  -H "Content-Type: application/json" `
  -H "Client: 10553" `
  -H "Authorization: Bearer ВАШ_ACCESS_TOKEN" `
  -d "{\"key\":\"KEY_ИЗ_SEND\",\"pin\":\"1234\"}"
```

**Успех:** `"success": true`

---

## 5. Сервер «Даром» (VNC, Терминал 1)

### Миграция БД (один раз)

```bash
cd /opt/darom_app
cat backend/db/migrate_plusofon_flash.sql | docker exec -i darom_db psql -U darom -d darom
```

**Успех:** `ALTER TABLE` без красного `ERROR`.

### Файл `.env`

```bash
nano /opt/darom_app/backend/.env
```

Добавьте или измените:

```env
VERIFY_PROVIDER=plusofon
PLUSOFON_FLASH_ACCESS_TOKEN=ваш_access_token_из_шага_3
PLUSOFON_MOCK=false
```

Mobile ID можно **оставить** для сброса PIN и админки:

```env
SMS_AUTH_MODE=mobile_id
SMS_AERO_MOBILE_ID_SIGN=...
```

Сохранить: `Ctrl+O` → Enter → `Ctrl+X`.

### Деплой backend

```bash
cd /opt/darom_app
git pull
cd backend && npm install
pm2 restart darom-api --update-env
pm2 logs darom-api --lines 15
```

**Успех в логах:**

```
✓ Plusofon Flash Call: боевой режим, VERIFY_PROVIDER=plusofon
```

### Проверка health

```bash
curl -s https://darom-app.online/api/health | head -c 800
```

Ищите блок:

```json
"verify":{"provider":"flash_call","plusofonConfigured":true,"plusofonReady":true}
```

---

## 6. Локальная разработка (ПК)

В `backend/.env`:

```env
VERIFY_PROVIDER=plusofon
PLUSOFON_MOCK=true
```

Без токена — звонок **не уходит**, код показывается на экране (как SMS_MOCK).

---

## 7. Проверка в приложении

**Терминал 2 (ПК):**

```powershell
cd C:\Users\User\Desktop\darom_app
flutter run -d chrome --web-port=8080
```

1. Войдите **новым** пользователем (или тем, у кого номер ещё не подтверждён)
2. Попробуйте **создать объявление** или **написать в чат**
3. Должен появиться диалог «Подтверждение номера»
4. Нажмите **«Подтвердить номер»** → на телефон звонок
5. Введите **последние 4 цифры** номера звонящего

**Успех:** «Готово! Теперь вам доступны все функции приложения!»

---

## Переменные `.env`

| Переменная | Значение |
|------------|----------|
| `VERIFY_PROVIDER=plusofon` | Только Плюсofon (если настроен) |
| `VERIFY_PROVIDER=mobile_id` | Старый SMS Aero Mobile ID |
| `VERIFY_PROVIDER=auto` | Плюсofon, если есть токен, иначе Mobile ID |
| `PLUSOFON_FLASH_ACCESS_TOKEN` | access_token аккаунта Flash Call |
| `PLUSOFON_MOCK=true` | Тест без звонков (код на экране) |

---

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| `Недостаточно прав` (403) | Используете токен **кабинета** вместо **access_token Flash Call** |
| Звонок не приходит | Баланс/пакет в lk.plusofon.ru; номер в формате `79...` |
| `Flashcall key not found` | Код истёк — запросите звонок заново |
| На МТС голосовой режим дороже | Используйте **классический** Flash Call (4 цифры номера), не «голосовой» |
| health: `plusofonReady: false` | Проверьте `PLUSOFON_FLASH_ACCESS_TOKEN` и `pm2 restart --update-env` |

---

## Экономика

| Способ | ~₽ за проверку |
|--------|----------------|
| SMS Aero Mobile ID (было) | **7,3** |
| Плюсofon Flash Call (пакет 1000) | **0,6** |
| Плюсofon (пакет 100 000) | **0,42** |

При **10 000** верификаций/мес: **~73 000 ₽** → **~6 000 ₽**.
