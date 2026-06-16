# Деплой «Даром» на Timeweb (этап B)

> Пользователь — новичок. Все команды — по шагам, с проверкой результата.

## Текущее состояние

| Компонент | Где | URL |
|-----------|-----|-----|
| Backend API | Сервер PM2 | http://5.129.243.246:3000/api/health |
| БД | Docker `darom_db` | порт 5433 на сервере |
| S3 фото | Yandex | `s3Ready: true`, бакет `darom-photos` |
| Flutter Web | **ПК** (localhost:8080) | ← **переносим на сервер** |

## Цель этапа B

Открывать приложение **с любого телефона/ПК** по адресу:

**http://5.129.243.246/**

Без запуска `flutter run` на домашнем компьютере.

---

## Шаг 1 — Собрать сайт на ПК

**Терминал на ПК** (PowerShell):

```powershell
cd C:\Users\User\Desktop\darom_app
flutter build web --release
```

**Успех:** папка `build\web` с файлами `index.html`, `main.dart.js` и т.д.

---

## Шаг 2 — Загрузить на сервер

Вариант **A** — через GitHub (если `build/` не в git, лучше вариант B):

На сервере после `git pull` собрать Flutter на сервере (нужен установленный Flutter).

Вариант **B** — WinSCP / FileZilla:

1. Подключиться к `5.129.243.246` (SFTP, пользователь root)
2. Создать папку `/var/www/darom`
3. Скопировать **содержимое** `C:\Users\User\Desktop\darom_app\build\web\` → `/var/www/darom/`

---

## Шаг 3 — Nginx на сервере

Консоль Timeweb (VNC):

```bash
apt update && apt install -y nginx
mkdir -p /var/www/darom
```

Скопировать конфиг из репозитория:

```bash
cp /opt/darom_app/deploy/nginx-darom.conf /etc/nginx/sites-available/darom
ln -sf /etc/nginx/sites-available/darom /etc/nginx/sites-enabled/darom
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

Открыть порт 80 в панели Timeweb (файрвол / группы безопасности).

**Проверка:** http://5.129.243.246/ — экран онбординга «Даром».

---

## Шаг 4 — Обновление сайта (после изменений в коде)

**На ПК:**

```powershell
cd C:\Users\User\Desktop\darom_app
flutter build web --release
```

Загрузить новые файлы в `/var/www/darom/` (WinSCP или `scp`).

**Backend** (если менялся только server-код):

```bash
cd /opt/darom_app && git pull && cd backend && npm install && pm2 restart darom-api
```

---

## Порты на сервере

| Порт | Сервис |
|------|--------|
| 80 | Nginx → Flutter Web |
| 3000 | Node.js API (PM2) |
| 5433 | PostgreSQL (Docker, только localhost) |

---

## Дальше (этап B+)

- Домен + HTTPS (Let's Encrypt)
- Nginx proxy `/api` → `:3000` (один адрес без порта в API)
