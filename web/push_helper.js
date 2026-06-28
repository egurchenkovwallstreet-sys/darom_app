// Push на Web — весь поток в JS, Dart получает только JSON-строку (без JS-interop TypeError).

window.daromGetNotificationPermission = function daromGetNotificationPermission() {
  try {
    if (typeof Notification === 'undefined') return 'unsupported';
    return String(Notification.permission || 'default');
  } catch (e) {
    return 'unsupported';
  }
};

window.daromRegisterWebPush = async function daromRegisterWebPush(vapidKey) {
  function reply(ok, fields) {
    var payload = { ok: ok };
    if (fields) {
      for (var key in fields) {
        if (Object.prototype.hasOwnProperty.call(fields, key)) {
          payload[key] = fields[key];
        }
      }
    }
    return JSON.stringify(payload);
  }

  try {
    if (typeof Notification === 'undefined') {
      return reply(false, { error: 'notifications_unsupported' });
    }
    if (!('serviceWorker' in navigator)) {
      return reply(false, { error: 'service_worker_unsupported' });
    }
    if (!vapidKey) {
      return reply(false, { error: 'vapid_key_missing' });
    }

    var permission = Notification.permission;
    if (permission === 'default') {
      permission = await Notification.requestPermission();
    }
    permission = String(permission);
    if (permission !== 'granted') {
      return reply(false, { error: 'permission_denied', permission: permission });
    }

    var loadScript = function (src) {
      return new Promise(function (resolve, reject) {
        if (document.querySelector('script[src="' + src + '"]')) {
          resolve();
          return;
        }
        var script = document.createElement('script');
        script.src = src;
        script.async = true;
        script.onload = function () { resolve(); };
        script.onerror = function () { reject(new Error('script_load_failed:' + src)); };
        document.head.appendChild(script);
      });
    };

    await loadScript('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
    await loadScript('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

    var cfg = await fetch('/api/config/firebase').then(function (r) { return r.json(); });
    if (!cfg || !cfg.configured) {
      return reply(false, { error: 'firebase_not_configured' });
    }

    if (!firebase.apps.length) {
      firebase.initializeApp({
        apiKey: cfg.api_key,
        appId: cfg.app_id,
        messagingSenderId: cfg.messaging_sender_id,
        projectId: cfg.project_id,
      });
    }

    var registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
    await navigator.serviceWorker.ready;

    for (var i = 0; i < 20; i += 1) {
      if (registration.active) break;
      await new Promise(function (r) { setTimeout(r, 150); });
    }

    var messaging = firebase.messaging();
    var token = await messaging.getToken({
      vapidKey: vapidKey,
      serviceWorkerRegistration: registration,
    });

    if (typeof token !== 'string' || !token) {
      return reply(false, { error: 'empty_fcm_token' });
    }

    return reply(true, { token: token });
  } catch (err) {
    var msg =
      (err && err.message) ||
      (err && err.code) ||
      (typeof err === 'string' ? err : 'fcm_unknown_error');
    return reply(false, { error: String(msg) });
  }
};

// Старый API — оставлен на случай кэша; всегда JSON-строка.
window.daromFetchFcmToken = async function daromFetchFcmToken(vapidKey) {
  var raw = await window.daromRegisterWebPush(vapidKey);
  try {
    var parsed = JSON.parse(raw);
    if (parsed && parsed.ok && parsed.token) return parsed.token;
    throw new Error((parsed && parsed.error) || 'fcm_token_failed');
  } catch (e) {
    throw new Error(e && e.message ? e.message : String(e));
  }
};
