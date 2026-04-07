const CACHE_NAME = 'medcontrol-v1';
const URLS_TO_CACHE = [
  'index(2).html',
  'manifest.json',
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

// Fetch: кэш первым, потом сеть
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  
  event.respondWith(
    caches.match(event.request).then(response => {
      return response || fetch(event.request).then(response => {
        if (response.ok) {
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, response.clone());
          });
        }
        return response;
      }).catch(() => {
        return new Response('Нет интернета', { status: 503 });
      });
    })
  );
});

// Фоновая синхронизация
self.addEventListener('sync', event => {
  if (event.tag === 'sync-logs') {
    event.waitUntil(syncLogs());
  }
});

async function syncLogs() {
  console.log('Синхронизация лекарств...');
}
