# Firebase Push — уведомления «Даром»

Push приходят при:

| Событие | Кому | Текст (пример) |
|---------|------|----------------|
| **Бронь** на 24 ч | Дарителю | «Иван забронировал(а) „Куртка“ на 24 ч» |
| **Новое сообщение** в чате | Собеседнику | «Мария · Куртка: Заберу завтра» |
| **«Отдал»** | Получателю | «Даритель отметил „Отдал“ — оцените сделку» |

Пока Firebase не настроен — backend пишет в логи `[PUSH MOCK]` (уведомления не уходят).

---

## 1. Создать проект Firebase (один раз, в браузере)

1. Откройте https://console.firebase.google.com/
2. **Добавить проект** → имя, например **Darom**
3. Google Analytics — можно **выключить**
4. После создания → **Project settings** (шестерёнка)

---

## 2. Web-приложение в Firebase

1. На главной проекта → иконка **`</>`** (Web)
2. Имя: **darom-web**
3. Скопируйте из блока `firebaseConfig`:
   - `apiKey`
   - `appId`
   - `messagingSenderId`
   - `projectId`

---

## 3. VAPID-ключ (для браузера)

1. Firebase Console → **Project settings** → вкладка **Cloud Messaging**
2. Блок **Web configuration** → **Generate key pair** (если ключа ещё нет)
3. Скопируйте **Key pair** — это `FIREBASE_WEB_VAPID_KEY`

---

## 4. Service Account (для backend)

1. **Project settings** → **Service accounts**
2. **Generate new private key** → скачается JSON-файл
3. Из файла нужны:
   - `project_id`
   - `client_email`
   - `private_key` (длинная строка с `-----BEGIN PRIVATE KEY-----`)

⚠️ JSON **не коммитьте** в Git и **не отправляйте** в чаты.

---

## 5. Настройка сервера (VNC Timeweb)

```bash
nano /opt/darom_app/backend/.env
```

Добавьте (подставьте **свои** значения):

```env
PUSH_MOCK=false
FIREBASE_PROJECT_ID=darom-xxxxx
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@darom-xxxxx.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
FIREBASE_WEB_API_KEY=AIza...
FIREBASE_WEB_APP_ID=1:123456789:web:abc...
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_WEB_VAPID_KEY=BExxxx...
```

**Важно для `FIREBASE_PRIVATE_KEY`:** в `.env` ключ в **одной строке**, переносы как `\n` (как в примере выше).

Миграция + перезапуск:

```bash
cd /opt/darom_app
git pull
cat backend/db/migrate_push_tokens.sql | docker exec -i darom_db psql -U darom -d darom
cd backend && npm install && pm2 restart darom-api --update-env
```

**На ПК** (миграция в локальный Docker):

```powershell
cd C:\Users\User\Desktop\darom_app
Get-Content backend\db\migrate_push_tokens.sql | docker exec -i darom_db psql -U darom -d darom
```

---

## 6. Деплой сайта

После `git push` подождите **GitHub Actions** (~5–10 мин), затем **Ctrl+F5** на https://darom-app.online/

---

## 7. Проверка

**A. Health API**

https://darom-app.online/api/health

```json
"push": { "mock": false, "configured": true, "ready": true }
```

**B. Конфиг для приложения**

https://darom-app.online/api/config/firebase

Должно быть `"configured": true` и ключи без секретов.

**C. На телефоне / в Chrome**

1. Войдите в приложение
2. Браузер спросит **«Разрешить уведомления?»** → **Разрешить**
3. Попросите другого пользователя **написать в чат** или **забронировать** ваше объявление
4. Должно прийти push-уведомление

**D. Логи backend**

```bash
pm2 logs darom-api --lines 30
```

Успех: `[PUSH] user=... type=chat_message sent=1`

Тест без Firebase: `[PUSH MOCK] user=...`

---

## 8. Если push не приходит

| Проблема | Решение |
|----------|---------|
| `push.mock: true` в health | `PUSH_MOCK=false` в `.env` |
| `configured: false` | Заполните все `FIREBASE_*` |
| Браузер не спросил разрешение | Настройки сайта → Уведомления → Разрешить |
| iPhone Safari | Push на iOS Web ограничены; надёжнее позже **Android-приложение** |
| `no_tokens` в логах | Пользователь не разрешил уведомления или не заходил после настройки |
| Ошибка private key | Проверьте `\n` в `FIREBASE_PRIVATE_KEY` |

---

## Локальная разработка (ПК)

В `backend/.env`:

```env
PUSH_MOCK=true
```

Push не отправляются — только строки `[PUSH MOCK]` в консоли backend.
