# Промпт для нового чата Cursor — «Даром»

Скопируйте блок ниже в **новый чат** (первое сообщение).

---

```
@docs/TZ_DAROM.md @docs/PROGRESS.md @deploy/README.md

Проект «Даром» — приложение бесплатной передачи вещей (Flutter + Node.js + PostgreSQL).

Я не программист — нужны пошаговые инструкции: что открыть, куда нажать, что должно получиться.

## Текущий статус (16.06.2026)

✅ Этап A завершён:
- Сервер Timeweb VPS 5.129.243.246
- Backend PM2 darom-api, health OK, S3 s3Ready:true (бакет darom-photos)
- Миграции БД на сервере прогнаны
- Flutter на ПК → удалённый API (всё протестировано: объявления, фото, чаты, избранное, аватар)

⏳ Этап B — СЕЙЧАС:
Полный переезд на сервер — выложить Flutter Web на http://5.129.243.246/
Чтобы не запускать flutter run на ПК. См. deploy/README.md и deploy/nginx-darom.conf

## Сервер
- Путь: /opt/darom_app
- Обновление backend: git pull → cd backend && npm install → pm2 restart darom-api
- Консоль: панель Timeweb → VNC (SSH с ПК не работает)
- .env на сервере: /opt/darom_app/backend/.env (S3 ключи заполнены)

## ПК (разработка)
- Путь: C:\Users\User\Desktop\darom_app
- Flutter: flutter run -d chrome --web-port=8080
- GitHub: push через GitHub Desktop
- Docker на ПК для разработки больше не нужен (backend на сервере)

## Задача
Помоги выполнить этап B пошагово: flutter build web, nginx, загрузка на сервер, проверка с телефона.
Потом — домен/HTTPS, Робокасca, SMS.ru, Firebase push.
```

---

## Кратко для себя

| | |
|---|---|
| **Репо** | github.com/egurchenkovwallstreet-sys/darom_app |
| **API health** | http://5.129.243.246:3000/api/health |
| **Сайт (цель B)** | http://5.129.243.246/ |
| **Следующий этап после B** | HTTPS + домен → Робокасса → Firebase |
