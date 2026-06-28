/* Firebase Cloud Messaging — service worker для darom-app.online */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

async function initFirebaseInServiceWorker() {
  const response = await fetch('/api/config/firebase');
  const cfg = await response.json();
  if (!cfg || !cfg.configured) return false;

  if (!firebase.apps.length) {
    firebase.initializeApp({
      apiKey: cfg.api_key,
      appId: cfg.app_id,
      messagingSenderId: cfg.messaging_sender_id,
      projectId: cfg.project_id,
    });
  }

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

  return true;
}

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(initFirebaseInServiceWorker());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
