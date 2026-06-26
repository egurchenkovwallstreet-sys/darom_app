# Этап I-D — заголовки безопасности nginx

> Пошагово для новичка. Делается **один раз** на сервере Timeweb (консоль VNC).

## Зачем

Браузеры и сканеры (Mozilla Observatory) проверяют заголовки ответа сайта. Без них ниже оценка безопасности и выше риск clickjacking / XSS.

## Что добавляем

| Заголовок | Зачем |
|-----------|--------|
| **Strict-Transport-Security (HSTS)** | Браузер всегда использует HTTPS |
| **X-Frame-Options** | Сайт нельзя встроить во «вредный» iframe |
| **X-Content-Type-Options** | Защита от подмены типа файла |
| **Referrer-Policy** | Меньше утечки URL при переходах |
| **Content-Security-Policy** | Ограничение источников скриптов и запросов |
| **Permissions-Policy** | Геолокация только для нашего сайта |

Готовый файл в репозитории: `deploy/nginx-security-headers.conf`

---

## Шаг 1 — Подтянуть код (VNC, Терминал 1)

```bash
cd /opt/darom_app
git fetch origin
git reset --hard origin/main
ls deploy/nginx-security-headers.conf
```

**Успех:** файл `deploy/nginx-security-headers.conf` существует.

---

## Шаг 2 — Открыть конфиг nginx

```bash
nano /etc/nginx/sites-available/darom
```

Прокрутите вниз (стрелки) и найдите блок **`server {`** с строками:

```nginx
listen 443 ssl;
listen [::]:443 ssl;
```

Это **HTTPS-блок** (не блок с `listen 80`).

---

## Шаг 3 — Добавить одну строку

Сразу **после** строк `ssl_certificate` / `ssl_certificate_key` (или после `server_name` в этом блоке) добавьте:

```nginx
    include /opt/darom_app/deploy/nginx-security-headers.conf;
```

Пример (ваш файл может чуть отличаться):

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name darom-app.online www.darom-app.online;

    ssl_certificate /etc/letsencrypt/live/darom-app.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/darom-app.online/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;

    include /opt/darom_app/deploy/nginx-security-headers.conf;

    root /var/www/darom;
    ...
}
```

Сохранить: **Ctrl+O** → Enter → **Ctrl+X**.

---

## Шаг 4 — Проверить и применить

```bash
nginx -t
```

**Успех:** `syntax is ok` и `test is successful`.

```bash
systemctl reload nginx
```

Без ошибок — готово.

---

## Шаг 5 — Проверка (VNC или ПК)

```bash
curl -sI https://darom-app.online/ | grep -iE 'strict-transport|x-frame|content-security|x-content-type|referrer-policy'
```

**Успех:** видны строки `Strict-Transport-Security`, `X-Frame-Options`, `Content-Security-Policy` и др.

**На ПК (PowerShell, Терминал 2):**

```powershell
curl.exe -sI "https://darom-app.online/"
```

В ответе должны быть заголовки `Strict-Transport-Security`, `X-Frame-Options`, `Content-Security-Policy`.

---

## Шаг 6 — Сайт работает?

1. Откройте https://darom-app.online/ — онбординг / вход.
2. Войдите по PIN — лента открывается.
3. Карта — тайлы OpenStreetMap загружаются.
4. Push (если включён) — без ошибок в консоли браузера (F12).

Если что-то сломалось — см. «Откат» ниже.

---

## Шаг 7 — Observatory (необязательно, на ПК)

1. Откройте https://observatory.mozilla.org/
2. Введите `darom-app.online` → **Scan**.
3. Цель: оценка **B** или лучше (было около −65 без заголовков).

---

## Откат (если сайт не открывается)

```bash
nano /etc/nginx/sites-available/darom
```

Удалите строку `include /opt/darom_app/deploy/nginx-security-headers.conf;`

```bash
nginx -t
systemctl reload nginx
```

---

## Чеклист I-D ✅

- [ ] `nginx -t` — ok
- [ ] `curl -sI https://darom-app.online/` — есть HSTS и CSP
- [ ] Сайт открывается, вход по PIN работает
- [ ] Карта и фото объявлений работают

После галочек — отметьте I-D в `docs/PROGRESS.md`.
