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

После настройки: **`git push`** → GitHub сам собирает сайт и заливает на сервер. WinSCP не нужен.

### Один раз: ключ и секреты

#### A. Создать ключ на ПК

**Терминал 1** (PowerShell):

```powershell
cd C:\Users\User\Desktop\darom_app
ssh-keygen -t ed25519 -C "github-deploy-darom" -f deploy_key -N ""
```

**Успех:** появились файлы `deploy_key` и `deploy_key.pub` в папке проекта.

#### B. Добавить публичный ключ на сервер

**Терминал 1** — скопируйте содержимое публичного ключа:

```powershell
Get-Content deploy_key.pub
```

Скопируйте **всю строку** (начинается с `ssh-ed25519`).

**Консоль Timeweb (VNC):**

```bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
nano /root/.ssh/authorized_keys
```

Вставьте строку ключа в **новую строку**, сохраните: `Ctrl+O`, Enter, `Ctrl+X`.

```bash
chmod 600 /root/.ssh/authorized_keys
```

#### C. Три секрета в GitHub

1. Откройте: https://github.com/egurchenkovwallstreet-sys/darom_app/settings/secrets/actions  
2. **New repository secret** — три раза:

| Имя | Значение |
|-----|----------|
| `VPS_HOST` | `5.129.243.246` |
| `VPS_USER` | `root` |
| `VPS_SSH_KEY` | **весь** текст файла `deploy_key` (от `-----BEGIN` до `-----END`) |

**Терминал 1** — показать приватный ключ для копирования:

```powershell
Get-Content deploy_key
```

⚠️ Файлы `deploy_key` / `deploy_key.pub` **не коммитить** — они уже в `.gitignore`.

#### D. Загрузить workflow в GitHub

**Терминал 1:**

```powershell
cd C:\Users\User\Desktop\darom_app
git add .github/workflows/deploy-web.yml
git add .
git commit -m "Автодеплой Flutter Web через GitHub Actions."
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

1. Откройте вкладку **Actions** на GitHub — зелёная галочка = успех (~5–10 мин).  
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

## Дальше (этап B+)

- Домен + HTTPS (Let's Encrypt)
- Nginx proxy `/api` → `:3000` (один адрес без порта в API)
