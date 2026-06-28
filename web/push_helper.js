// Получение FCM-токена на Web с явной привязкой к firebase-messaging-sw.js
window.daromFetchFcmToken = async function daromFetchFcmToken(vapidKey) {
  try {
    if (!('serviceWorker' in navigator)) {
      throw new Error('service_worker_unsupported');
    }
    if (!vapidKey) {
      throw new Error('vapid_key_missing');
    }

    const loadScript = (src) =>
      new Promise((resolve, reject) => {
        if (document.querySelector('script[src="' + src + '"]')) {
          resolve();
          return;
        }
        const script = document.createElement('script');
        script.src = src;
        script.async = true;
        script.onload = () => resolve();
        script.onerror = () => reject(new Error('script_load_failed:' + src));
        document.head.appendChild(script);
      });

    await loadScript('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
    await loadScript('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

    const cfg = await fetch('/api/config/firebase').then((r) => r.json());
    if (!cfg || !cfg.configured) {
      throw new Error('firebase_not_configured');
    }

    if (!firebase.apps.length) {
      firebase.initializeApp({
        apiKey: cfg.api_key,
        appId: cfg.app_id,
        messagingSenderId: cfg.messaging_sender_id,
        projectId: cfg.project_id,
      });
    }

    const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
    await navigator.serviceWorker.ready;

    for (let i = 0; i < 20; i += 1) {
      if (registration.active) break;
      await new Promise((r) => setTimeout(r, 150));
    }

    const messaging = firebase.messaging();
    const token = await messaging.getToken({
      vapidKey: vapidKey,
      serviceWorkerRegistration: registration,
    });

    if (typeof token !== 'string' || !token) {
      throw new Error('empty_fcm_token');
    }

    return token;
  } catch (err) {
    // Важно: только строка в Error — иначе Dart JS-interop падает с TypeError (minified:FK).
    const msg =
      (err && err.message) ||
      (err && err.code) ||
      (typeof err === 'string' ? err : 'fcm_unknown_error');
    throw new Error(String(msg));
  }
};
