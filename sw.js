/* ==========================================================================
   SKS Car — Progressive Web App (PWA) Offline Service Worker
   ========================================================================== */
const SKS_CACHE_NAME = 'sks-car-pwa-v4';
const SKS_CORE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './css/style.css',
  './js/data.js',
  './js/app.js',
  './js/paho-mqtt.min.js',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/sks-icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SKS_CACHE_NAME).then((cache) => {
      return cache.addAll(SKS_CORE_ASSETS).catch(() => {});
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.map((key) => {
          if (key !== SKS_CACHE_NAME) return caches.delete(key);
        })
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  // Never cache live sync/cloud API calls
  if (
    url.pathname.includes('/api/state') ||
    url.hostname.includes('firebaseio.com') ||
    url.hostname.includes('firebasedatabase.app') ||
    url.hostname.includes('supabase.co') ||
    url.hostname.includes('emqx.io') ||
    url.hostname.includes('hivemq.com')
  ) {
    return;
  }

  // Network-first for app files so updates arrive immediately, with offline cache fallback
  event.respondWith(
    fetch(req)
      .then((res) => {
        if (res && res.status === 200 && url.origin === self.location.origin) {
          const clone = res.clone();
          caches.open(SKS_CACHE_NAME).then((cache) => cache.put(req, clone)).catch(() => {});
        }
        return res;
      })
      .catch(() => caches.match(req).then((cached) => cached || caches.match('./index.html')))
  );
});
