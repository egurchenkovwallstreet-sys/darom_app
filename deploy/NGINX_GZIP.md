# Сжатие gzip для Flutter Web (darom-app.online)

> Без gzip браузер качает **~10 МБ** (main.dart.js + canvaskit.wasm). С gzip — примерно **в 3–4 раза меньше**.

## Один раз на сервере (VNC, Терминал 1)

На Timeweb в `/etc/nginx/nginx.conf` уже есть `gzip on;`. Копировать `deploy/nginx-gzip.conf` целиком **нельзя** — nginx выдаст ошибку `gzip directive is duplicate`.

```bash
cd /opt/darom_app
git pull
sudo sed '/^gzip on;/d' deploy/nginx-gzip.conf | sudo tee /etc/nginx/conf.d/darom-gzip.conf > /dev/null
sudo nginx -t
sudo systemctl reload nginx
```

**Успех:** `nginx -t` пишет `syntax is ok`, `test is successful`.

## Проверка с ПК (Терминал 2)

```powershell
curl.exe -sSI -H "Accept-Encoding: gzip" "https://darom-app.online/main.dart.js"
```

**Успех:** в ответе есть строка `Content-Encoding: gzip`.

```powershell
curl.exe -sSI -H "Accept-Encoding: gzip" "https://darom-app.online/canvaskit/canvaskit.wasm"
```

**Успех:** тоже `Content-Encoding: gzip`.

## Если gzip не включился

1. Убедитесь, что файл лежит в `/etc/nginx/conf.d/darom-gzip.conf`
2. В `/etc/nginx/nginx.conf` не должно быть глобального `gzip off;`
3. После правок: `sudo nginx -t && sudo systemctl reload nginx`
