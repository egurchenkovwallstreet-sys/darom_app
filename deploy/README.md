# Деплой «Даром» на Timeweb (этап B)

> Пользователь — новичок. Все команды — по шагам, с проверкой результата.

## Текущее состояние

| Компонент | Где | URL |
|-----------|-----|-----|
| Backend API | Сервер PM2 | http://5.129.243.246:3000/api/health |
| БД | Docker `darom_db` | порт 5433 на сервере |
| S3 фото | Yandex | `s3Ready: true`, бакет `darom-photos` |
| Flutter Web | Сервер `/var/www/darom` | http://5.129.243.246/ |

---

## Автодеплой сайта через GitHub Actions (рекомендуется)

После настройки: **`git push`** → GitHub собирает сайт и отправляет на сервер **через API** (порт 3000). SSH и WinSCP не нужны.

### Один раз: пароль деплоя

#### A. Придумайте длинный пароль

Например: `DaromWebDeploy2026Xy7zK9mN` (свой, никому не показывайте).

Запишите — он нужен в **двух местах** (сервер + GitHub).

#### B. Добавить пароль на сервер

**Консоль Timeweb (VNC):**

```bash
nano /opt/darom_app/backend/.env
```

В **конец файла** добавьте (подставьте **свой** пароль):

```
DEPLOY_SECRET=DaromWebDeploy2026Xy7zK9mN
WEB_ROOT=/var/www/darom
```

Сохраните: `Ctrl+O`, Enter, `Ctrl+X`.

Перезапустите backend:

```bash
cd /opt/darom_app && git pull && cd backend && npm install && pm2 restart darom-api
```

#### C. Два секрета в GitHub

1. Откройте: https://github.com/egurchenkovwallstreet-sys/darom_app/settings/secrets/actions  
2. **New repository secret** — два раза:

| Имя | Значение |
|-----|----------|
| `VPS_HOST` | `5.129.243.246` |
| `DEPLOY_SECRET` | **тот же пароль**, что в `.env` на сервере |

Секреты `VPS_USER` и `VPS_SSH_KEY` **больше не нужны** (можно удалить).

#### E. Если Deploy Backend красный (❌) в GitHub Actions

1. Откройте последний запуск → шаг **Deploy backend via API** → прочитайте текст ошибки.
2. **403 Forbidden** — пароль `DEPLOY_SECRET` в GitHub **не совпадает** с `/opt/darom_app/backend/.env` на сервере.  
   На VNC: `grep DEPLOY_SECRET /opt/darom_app/backend/.env` — скопируйте значение **без пробелов** в GitHub Secret.
3. **503** — на сервере нет строки `DEPLOY_SECRET=` в `.env` (добавьте по шагу B выше).
4. **curl exit 7** (старые запуски) — workflow ошибочно пробовал порт `:3000` снаружи; после обновления workflow должна быть понятная ошибка 403 или успех.

После исправления секрета: Actions → **Deploy Backend** → **Run workflow** → Run workflow.

#### D. Отправить код на GitHub

**Терминал 1** (PowerShell):

```powershell
cd C:\Users\User\Desktop\darom_app
git add .
git commit -m "Деплой сайта через API."
git push
```

### Каждый раз при изменении интерфейса

**Терминал 1:**

```powershell
cd C:\Users\User\Desktop\darom_app
git add .
git commit -m "кратко: что изменили"
git push
```

1. Откройте **Actions** на GitHub — ждите **зелёную галочку** (~5–10 мин).  
2. Проверьте http://5.129.243.246/

**Backend** (только server-код, без Flutter):

```bash
cd /opt/darom_app && git pull && cd backend && npm install && pm2 restart darom-api
```

---

## Ручной деплой (WinSCP) — запасной вариант

### Шаг 1 — Собрать сайт на ПК

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

## Этап B+ — домен + HTTPS

**Подробная инструкция:** [`deploy/DOMAIN_HTTPS.md`](DOMAIN_HTTPS.md)

Кратко: DNS → A-запись на `5.129.243.246` → nginx (`nginx-darom-https.conf`) → certbot → `git push`.

| После B+ | URL |
|-----------|-----|
| Сайт | https://darom-app.online/ |
| API | https://darom-app.online/api/health |
