# PM2 cluster (2 процесса Node)

Используйте после деплоя backend с `ecosystem.config.js`.

## Зачем

На сервере **2 ядра CPU**. Один процесс Node использует только одно ядро. Cluster — два процесса, меньше очередь при нагрузке.

## Шаги на сервере (VNC)

**Терминал на сервере** (не на ПК):

```bash
cd /opt/darom_app
git pull
cd backend
npm install
pm2 delete darom-api
pm2 start ecosystem.config.js
pm2 save
pm2 status
```

**Успех:** в `pm2 status` две строки `darom-api` со статусом `online`.

**Проверка:**

```bash
curl -s https://darom-app.online/api/health | head -c 200
```

Должен быть `"ok":true` и блок `"metrics"`.

## Откат на один процесс

```bash
cd /opt/darom_app/backend
pm2 delete darom-api
pm2 start src/index.js --name darom-api
pm2 save
```

## Миграция индексов (опционально, после cluster)

```bash
docker exec -i darom_db psql -U darom -d darom < /opt/darom_app/backend/db/migrate_geo_indexes.sql
```

Без ошибок — индексы уже есть или созданы.
