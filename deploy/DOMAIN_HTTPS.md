# Этап B+ — домен darom-app.online + HTTPS

> Пошагово для новичка. Домен: **Reg.ru** | Сервер: Timeweb VPS `5.129.243.246`.

## Что получится в конце

| Было | Станет |
|------|--------|
| http://5.129.243.246/ | https://darom-app.online/ |
| API http://5.129.243.246:3000 | https://darom-app.online/api/... (без порта) |
| Геолокация на сайте не работает | Работает (браузер требует HTTPS) |
| Замок «не защищено» | Зелёный замок Let's Encrypt |

---

## Шаг 1 — DNS в Reg.ru

1. Откройте https://www.reg.ru/ и войдите в аккаунт.
2. **Домены** → **darom-app.online** → **Управление DNS** (или «DNS-серверы и зона»).
3. Убедитесь, что используются **DNS-серверы Reg.ru** (ns1.reg.ru, ns2.reg.ru), не сторонние.
4. Добавьте или измените **две A-записи**:

| Тип | Subdomain (поддомен) | IP-адрес |
|-----|----------------------|----------|
| **A** | `@` (корень, иногда «пусто») | `5.129.243.246` |
| **A** | `www` | `5.129.243.246` |

5. Удалите лишние A/CNAME для `@` и `www`, если они указывают на другой IP или на parking Reg.ru.

**Проверка — Терминал 1 (PowerShell на ПК):**

```powershell
nslookup darom-app.online
nslookup www.darom-app.online
```

**Успех:** в ответе адрес `5.129.243.246`.  
**Если другой IP:** подождите 5–30 мин (иногда до 24 ч) и повторите.

**Проверка в браузере:** http://darom-app.online/ — тот же сайт «Даром», что и по IP (пока без HTTPS).

---

## Шаг 2 — Открыть порт 443 (HTTPS) в Timeweb

1. Панель Timeweb → ваш VPS `5.129.243.246`.
2. **Сеть** / **Firewall** / **Группы безопасности**.
3. Разрешите входящий **TCP 443** (как уже открыт порт 80).

---

## Шаг 3 — Nginx на сервере (консоль VNC)

1. Timeweb → VPS → **Консоль** (VNC).

2. Подтянуть код и применить конфиг:

```bash
cd /opt/darom_app && git pull
cp /opt/darom_app/deploy/nginx-darom-https.conf /etc/nginx/sites-available/darom
ln -sf /etc/nginx/sites-available/darom /etc/nginx/sites-enabled/darom
rm -f /etc/nginx/sites-enabled/default
nginx -t
```

**Успех:** `syntax is ok` и `test is successful`.

3. Применить:

```bash
systemctl reload nginx
```

4. Проверка API:

```bash
curl -s http://127.0.0.1/api/health
```

**Успех:** JSON с `"ok":true`.

5. В браузере на ПК:
   - http://darom-app.online/api/health — JSON с `ok:true`
   - http://darom-app.online/ — сайт открывается

> Если `git pull` не находит файл — сначала выполните **Шаг 5** на ПК (`git push`), затем снова `git pull`.

---

## Шаг 4 — SSL-сертификат (Let's Encrypt)

**На сервере (VNC):**

```bash
apt update && apt install -y certbot python3-certbot-nginx
certbot --nginx -d darom-app.online -d www.darom-app.online
```

Certbot спросит:

1. **Email** — ваш e-mail.
2. **Terms** — `Y`.
3. **Share email** — по желанию `N`.
4. **Redirect HTTP → HTTPS** — выберите **2**.

**Успех:** `Congratulations!` и https://darom-app.online/ с **замком**.

```bash
curl -s https://darom-app.online/api/health
```

---

## Шаг 5 — Отправить код на GitHub (ПК)

**Терминал 1 (PowerShell):**

```powershell
cd C:\Users\User\Desktop\darom_app
git add .
git commit -m "Домен darom-app.online: nginx, API, документация."
git push
```

Дождитесь **зелёной галочки** в GitHub Actions (~5–10 мин).

**Проверка:**

1. https://darom-app.online/ — онбординг, замок в адресной строке.
2. Вход по PIN/SMS — данные загружаются.
3. Кнопка «Моё местоположение» на главной (HTTPS).

---

## Шаг 6 — Автопродление сертификата

```bash
certbot renew --dry-run
```

**Успех:** `Congratulations, all simulated renewals succeeded`.

---

## Если что-то пошло не так

| Проблема | Что делать |
|----------|------------|
| `nslookup` не показывает ваш IP | Подождать DNS; проверить A-записи в Reg.ru |
| `nginx -t` — ошибка | Пришлите текст ошибки |
| certbot: «Connection refused» | Порт 80 открыт? http://darom-app.online/ открывается? |
| Сайт HTTPS, вход не работает | https://darom-app.online/api/health; `pm2 logs darom-api --lines 30` |
| Старый IP | http://5.129.243.246/ по-прежнему работает |

---

## Чеклист «этап B+ готов»

- [ ] https://darom-app.online/ — замок
- [ ] https://darom-app.online/api/health → `"ok":true`
- [ ] Вход по PIN/SMS на https://darom-app.online/
- [ ] `certbot renew --dry-run` — успех

После галочек — этап B+ ✅ в `docs/PROGRESS.md`.
