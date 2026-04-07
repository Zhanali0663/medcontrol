const CACHE_NAME = 'medcontrol-v2';
const URLS_TO_CACHE = [
  './',
  './index.html',
  './manifest.json',
];

// Установка Service Worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(URLS_TO_CACHE).catch(() => {});
    })
  );
  self.skipWaiting();
});

// Активация
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch: сеть первой, потом кэш, потом index.html для SPA
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  
  event.respondWith(
    fetch(event.request)
      .then(response => {
        // Если ошибка 404 и это не файл - показать index.html
        if (response.status === 404 && !event.request.url.includes('.')) {
          return caches.match('./index.html') || fetch('./index.html');
        }
        
        if (response.ok) {
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, response.clone());
          });
        }
        return response;
      })
      .catch(() => {
        // Офлайн - пытаемся вернуть из кэша
        return caches.match(event.request).then(response => {
          return response || caches.match('./index.html') || new Response('Нет интернета', { status: 503 });
        });
      })
  );
});

// Обработка push-уведомлений
self.addEventListener('push', event => {
  if (!event.data) return;
  
  try {
    const data = event.data.json();
    const options = {
      body: data.body || 'Новое уведомление',
      icon: '💊',
      badge: '💊',
      tag: data.tag || 'med-notification',
      requireInteraction: true,
      actions: [
        { action: 'open', title: '👁️ Открыть' },
        { action: 'close', title: '✕ Закрыть' }
      ]
    };
    
    event.waitUntil(
      self.registration.showNotification(data.title || '💊 МедКонтроль', options)
    );
  } catch (e) {
    console.error('Push notification error:', e);
  }
});

// Клик на уведомление
self.addEventListener('notificationclick', event => {
  event.notification.close();
  
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(clientList => {
      // Если окно уже открыто - сфокусируем его
      for (let i = 0; i < clientList.length; i++) {
        if (clientList[i].url === '/' && 'focus' in clientList[i]) {
          return clientList[i].focus();
        }
      }
      // Если нет - откроем новое
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

// Закрытие уведомления
self.addEventListener('notificationclose', event => {
  console.log('Notification closed');
});
