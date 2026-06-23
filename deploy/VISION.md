# Yandex Vision — модерация фото «Даром»

При загрузке фото к объявлению или аватару сервер проверяет изображение через **Yandex Vision**:

| Проверка | Что делает |
|----------|------------|
| **Moderation** | Отклоняет взрослый контент и насилие |
| **OCR (текст на фото)** | Ищет запрещённые слова и товары (лекарства, алкоголь и т.д.) |

Пока Vision не включён — фото проходят без проверки (`PHOTO_MOCK_MODERATION=true`).

---

## 1. Yandex Cloud (один раз, в браузере)

1. Откройте https://console.yandex.cloud/
2. Войдите в тот же аккаунт, где уже настроен **Object Storage** для фото (бакет `darom-photos`).
3. Выберите **каталог** (folder) — тот же, где S3.
4. Скопируйте **ID каталога** (строка вида `b1gxxxxxxxxxx`) — понадобится для `YC_FOLDER_ID`.

---

## 2. Сервисный аккаунт и Api-Key

1. В каталоге: **Сервисные аккаунты** → **Создать сервисный аккаунт**  
   Имя, например: `darom-vision`
2. **Назначить роли** → добавьте роль **`ai.vision.user`**
3. Откройте созданный аккаунт → вкладка **API-ключи** → **Создать API-ключ**
4. Скопируйте ключ **сразу** (потом его не покажут) — это `YC_VISION_API_KEY`

⚠️ Ключ **не коммитьте** в Git и **не отправляйте** в чаты.

---

## 3. Настройка сервера (VNC Timeweb)

**Терминал 1** — подключитесь к серверу и откройте файл настроек:

```bash
nano /opt/darom_app/backend/.env
```

Добавьте или измените строки (подставьте **свои** значения):

```env
PHOTO_MOCK_MODERATION=false
YC_VISION_API_KEY=AQVNxxxxxxxxxxxxxxxx
YC_FOLDER_ID=b1gxxxxxxxxxx
YC_VISION_MODERATION_THRESHOLD=0.6
```

Сохраните: `Ctrl+O`, Enter, `Ctrl+X`.

---

## 4. Обновление кода и перезапуск

В том же **Терминале 1**:

```bash
cd /opt/darom_app
git pull
cd backend
npm install
pm2 restart darom-api --update-env
pm2 logs darom-api --lines 30
```

**Успех:** в логах есть строка вида  
`✓ Yandex Vision: moderation threshold 0.6, folder b1g...`

**Если ошибка при `npm install` (sharp):** на сервере нужны инструменты сборки. Напишите в поддержку Timeweb или выполните (если есть права root):

```bash
apt-get update && apt-get install -y build-essential
cd /opt/darom_app/backend && npm install
```

---

## 5. Проверка

1. В браузере откройте: https://darom-app.online/api/health  
2. Должно быть:

```json
"vision": {
  "mock": false,
  "configured": true,
  "ready": true,
  "threshold": 0.6
}
```

3. На сайте создайте объявление и загрузите **обычное фото вещи** — должно сохраниться.
4. Попробуйте фото с крупной надписью «продам» или «водка» — должна быть **ошибка** и фото не добавится.

---

## 6. Локальная разработка на ПК

На компьютере можно оставить тестовый режим (без Vision):

```env
PHOTO_MOCK_MODERATION=true
```

Flutter по-прежнему:

```powershell
cd C:\Users\User\Desktop\darom_app
flutter run -d chrome --web-port=8080
```

API на продакшене будет проверять фото через Vision, даже если на ПК mock включён.

---

## Частые проблемы

| Симптом | Что делать |
|---------|------------|
| `vision.mock: true` на health | Проверьте `PHOTO_MOCK_MODERATION=false` и непустой `YC_VISION_API_KEY`, затем `pm2 restart darom-api --update-env` |
| «Проверка фото не настроена» | Заполните `YC_VISION_API_KEY` или временно `PHOTO_MOCK_MODERATION=true` |
| HTTP 403 от Vision | У сервисного аккаунта должна быть роль `ai.vision.user` |
| «Сервис проверки фото временно недоступен» | Проверьте интернет с VPS, ключ и логи: `pm2 logs darom-api` |
| Большое фото с телефона | Сервер сам сжимает до 1 МБ для Vision; оригинал сохраняется в S3 |

---

## Стоимость

Yandex Vision тарифицируется по запросам. Один загрузенный снимок = один запрос `batchAnalyze` (moderation + OCR). Следите за расходами в консоли Yandex Cloud → **Биллинг**.
