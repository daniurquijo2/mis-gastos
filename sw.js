// Service worker mínimo: cachea el "armazón" de la app para que arranque rápido
// y funcione aunque la conexión sea mala. Los datos siempre vienen de Supabase (red).
const CACHE = 'gastos-v7';
const SHELL = ['./', './index.html', './manifest.webmanifest', './logo.svg', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Nunca cachear llamadas a Supabase (datos y fotos siempre frescos)
  if (url.hostname.endsWith('supabase.co')) return;

  // Navegación: red primero, con respaldo a la copia cacheada
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req).catch(() => caches.match('./index.html')));
    return;
  }
  // Resto: cache primero, si no, red
  e.respondWith(caches.match(req).then(hit => hit || fetch(req)));
});
