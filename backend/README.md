# Backend «Даром»

Node.js + Express + PostgreSQL + PostGIS.

## Быстрый старт

```powershell
# 1. Из корня проекта — запустить базу
docker compose up -d

# 2. Установить зависимости backend
cd backend
copy .env.example .env
npm install

# 3. Запустить сервер
npm run dev
```

Проверка в браузере:

- http://localhost:3000/api/health — сервер и БД

> База слушает порт **5433** (на 5432 у вас уже стоит другой PostgreSQL в Windows).
- http://localhost:3000/api/listings?category=Одежда&subcategory=Мужская — тестовые объявления

## Структура

```
backend/
  db/init.sql       — схема и тестовые данные
  src/
    index.js        — точка входа
    config.js       — настройки из .env
    db/pool.js      — подключение к PostgreSQL
    routes/         — API-маршруты
```
