/* Firebase Cloud Messaging — service worker для darom-app.online
   Конфиг подтягивается с API (не нужно править вручную после настройки .env). */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

fetch('/api/config/firebase')
  .then((response) => response.json())
  .then((cfg) => {
    if (!cfg || !cfg.configured) return;
    firebase.initializeApp({
      apiKey: cfg.api_key,
      appId: cfg.app_id,
      messagingSenderId: cfg.messaging_sender_id,
      projectId: cfg.project_id,
    });
    const messaging = firebase.messaging();
    messaging.onBackgroundMessage((payload) => {
      const title = payload.notification?.title || 'Даром';
      const options = {
        body: payload.notification?.body || '',
        icon: '/icons/Icon-192.png',
        data: payload.data || {},
      };
      return self.registration.showNotification(title, options);
    });
  })
  .catch(() => {});
