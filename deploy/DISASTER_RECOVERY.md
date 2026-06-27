# Восстановление после сбоев («Даром»)

> Пошаговая инструкция для **не программиста**. Этап J-F, 27.06.2026.  
> Держите распечатку или закладку на этот файл.

---

## Быстрая проверка «жив ли сайт»

**Терминал 2 (PowerShell на ПК):**

```powershell
curl.exe -s "https://darom-app.online/api/health"
```

**Успех:** текст с `"ok":true` и `"security":{"stage":"J-B"` (или новее).

**Сайт не открывается в браузере:** см. разделы ниже по очереди.

---

## 1. Потеря доступа к GitHub

| Что проверить | Куда зайти | Что сделать |
|---------------|------------|-------------|
| 2FA включена | github.com → Settings → Password and authentication | Включить 2FA, сохранить **recovery codes** в надёжное место (не в репозиторий!) |
| Репозиторий | github.com/egurchenkovwallstreet-sys/darom_app | Убедиться, что видите репозиторий |
| Secrets Actions | Repo → Settings → Secrets → Actions | Должны быть `VPS_HOST`, `DEPLOY_SECRET` |
| Второй человек | Settings → Collaborators | Рекомендуется добавить доверенного maintainer |

**Если заблокирован вход:** восстановление через email + recovery codes GitHub.

**Код на сервере остаётся** в `/opt/darom_app` — сайт может работать без GitHub.

---

## 2. Потеря VPS Timeweb

| Что проверить | Где |
|---------------|-----|
| Пароль панели | timeweb.com → ваш аккаунт |
| 2FA | Настройки безопасности Timeweb |
| VNC/SSH | Панель VPS → консоль |
| IP сервера | Должен быть **5.129.243.246** |

**Восстановление на новом VPS (кратко):**

1. Ubuntu + Docker + Node + nginx + certbot (см. `deploy/README.md`)
2. `git clone` репозитория в `/opt/darom_app`
3. Скопировать **backup `.env`** в `backend/.env` (см. раздел 5)
4. Docker: `darom_db`, миграции: `bash backend/scripts/run_all_migrations.sh`
5. `pm2 start` backend, nginx, certbot
6. Обновить DNS (Cloudflare + Reg.ru) на новый IP если IP сменился

---

## 3. Потеря домена Reg.ru

| Что проверить | Где |
|---------------|-----|
| Срок домена **darom-app.online** | reg.ru → Домены |
| Автопродление | Включить |
| 2FA Reg.ru | Включить |
| NS-записи | Должны указывать на Cloudflare (`kira`, `weston`.ns.cloudflare.com) |

**Пока домен недоступен:** запасной вход по IP http://5.129.243.246/ (без HTTPS на IP — только временно).

---

## 4. Потеря Cloudflare

| Что проверить | Где |
|---------------|-----|
| 2FA | dash.cloudflare.com |
| DNS A `@` и `www` | → **5.129.243.246**, режим **DNS only** (серое ☁️) |
| SSL mode | **Full (strict)** |

⚠️ **Не включайте оранжевое облако (Proxied)** — в РФ сайт может не открываться без VPN.

---

## 5. Потеря `.env` / секретов

**Где должен быть backup (НЕ в GitHub):**

- Флешка / облако с паролем / менеджер паролей
- Копия: `/opt/darom_app/backend/.env` на сервере

**Минимальный список переменных:** см. `backend/.env.example` (если есть) или `deploy/` инструкции (SMS, SMTP, FIREBASE, ROBOKASSA, S3, DEPLOY_SECRET).

**После восстановления `.env` на сервере (VNC):**

```bash
cd /opt/darom_app/backend
pm2 restart darom-api --update-env
curl -s http://127.0.0.1:3000/api/health
```

---

## 6. Потеря базы данных

| Что проверить | Где |
|---------------|-----|
| Контейнер | `docker ps` → `darom_db` |
| Бэкап Timeweb | Панель VPS → Бэкапы (если включены) |
| Ручной дамп | Рекомендуется **еженедельно** (команда ниже) |

**Создать бэкап (VNC, Терминал 1 на сервере):**

```bash
docker exec darom_db pg_dump -U darom darom > /opt/darom_backups/darom_$(date +%Y%m%d).sql
```

**Восстановить из файла:**

```bash
cat /opt/darom_backups/darom_YYYYMMDD.sql | docker exec -i darom_db psql -U darom -d darom
pm2 restart darom-api --update-env
```

---

## 7. Потеря админки

| Ситуация | Решение |
|----------|---------|
| Забыл PIN | SMS сброс PIN (`reset_pin`) |
| Нет доступа к admin-телефону | Таблица `admin_users` в PostgreSQL — только через VNC/доверенного DBA |
| super_admin один | Добавьте второй телефон в `admin_users` заранее (миграция/SQL) |

URL запасной: https://darom-app.online/admin

---

## 8. Компрометация DEPLOY_SECRET

1. Сгенерировать новый длинный секрет (32+ символа)
2. Обновить `backend/.env` на сервере: `DEPLOY_SECRET=...`
3. Обновить GitHub Secret `DEPLOY_SECRET`
4. `pm2 restart darom-api --update-env`

Без секрета никто не сможет вызвать `/api/deploy-web` и `/api/deploy-backend`.

---

## 9. SSL истёк

**На сервере (VNC):**

```bash
certbot renew --dry-run
certbot renew
systemctl reload nginx
```

Проверка: https://darom-app.online/ — замок в браузере.

---

## 10. PM2 / backend упал

**VNC:**

```bash
pm2 status
pm2 logs darom-api --lines 30
pm2 restart darom-api --update-env
```

**Если не помогло:**

```bash
cd /opt/darom_app && git fetch origin && git reset --hard origin/main
cd backend && npm install && pm2 restart darom-api --update-env
```

---

## Чеклист «раз в месяц» (5 минут)

- [ ] `curl.exe "https://darom-app.online/api/health"` — ok + актуальный stage
- [ ] Три curl из `docs/TZ_DAROM.md` §13.4 (401, 403, админка)
- [ ] `nslookup darom-app.online 8.8.8.8` → 5.129.243.246
- [ ] Срок домена Reg.ru
- [ ] Свежий pg_dump (раздел 6)
- [ ] Recovery codes GitHub на месте

---

*Обновляйте этот файл после изменений инфраструктуры.*
