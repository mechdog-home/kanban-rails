/**
 * Service Worker for Kanban Board PWA
 * 
 * This service worker provides offline support and caching for the
 * Kanban Board Progressive Web App.
 * 
 * FEATURES:
 * - Cache static assets (CSS, JS, images)
 * - Cache API responses for offline viewing
 * - Background sync for offline task updates
 * - Push notification support (future)
 */

const CACHE_NAME = 'kanban-board-v1';
const STATIC_ASSETS = [
  '/',
  '/tasks',
  '/manifest.json',
  '/icon.svg',
  '/icon.png',
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[Service Worker] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => {
        console.log('[Service Worker] Install complete');
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== CACHE_NAME) {
              console.log('[Service Worker] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('[Service Worker] Activate complete');
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip cross-origin requests
  if (url.origin !== self.location.origin) {
    return;
  }
  
  // Strategy: Cache First for static assets, Network First for API
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request));
  } else if (isAPIRequest(url.pathname)) {
    event.respondWith(networkFirst(request));
  }
});

// Check if request is for a static asset
function isStaticAsset(pathname) {
  const staticExtensions = ['.css', '.js', '.png', '.jpg', '.svg', '.ico', '.woff', '.woff2'];
  return staticExtensions.some(ext => pathname.endsWith(ext)) ||
         pathname === '/' ||
         pathname === '/tasks';
}

// Check if request is for API
function isAPIRequest(pathname) {
  return pathname.startsWith('/api/');
}

// Cache First strategy: Try cache, fall back to network
async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  
  if (cached) {
    // Return cached response and update cache in background
    fetch(request).then((response) => {
      if (response.ok) {
        cache.put(request, response);
      }
    }).catch(() => {});
    
    return cached;
  }
  
  // Not in cache, fetch from network
  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    console.error('[Service Worker] Fetch failed:', error);
    return new Response('Offline', { status: 503 });
  }
}

// Network First strategy: Try network, fall back to cache
async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      // Update cache with fresh data
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.log('[Service Worker] Network failed, trying cache');
    const cached = await cache.match(request);
    
    if (cached) {
      return cached;
    }
    
    // Return offline response for API
    return new Response(
      JSON.stringify({ error: 'Offline', message: 'Network unavailable' }),
      { 
        status: 503, 
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

// Background sync for offline task updates (future feature)
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-tasks') {
    console.log('[Service Worker] Background sync triggered');
    // TODO: Sync pending task updates
  }
});

// Push notification support (future feature)
self.addEventListener('push', (event) => {
  console.log('[Service Worker] Push received:', event);
  // TODO: Show notification
});
