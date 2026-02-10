// ============================================================================
// PWA Registration Script
// ============================================================================
//
// This script registers the Service Worker for Progressive Web App support.
// It enables:
// - Offline functionality
// - Background sync
// - Push notifications (future)
// - Add to Home Screen on mobile/desktop
//
// LEARNING NOTES:
//
// WHAT IS A SERVICE WORKER?
// A service worker is a JavaScript file that runs in the background, separate
// from the web page. It acts as a proxy between your app and the network,
// enabling offline support and other PWA features.
//
// PWA REQUIREMENTS:
// 1. HTTPS (required for service workers)
// 2. Web App Manifest (manifest.json)
// 3. Service Worker with fetch handler
// 4. Icons in multiple sizes
//
// INSTALLATION:
// On mobile: "Add to Home Screen" prompt appears automatically
// On desktop: Chrome shows install icon in address bar
//           Edge: Menu > Apps > Install this site as an app
//           Safari: Share > Add to Home Screen (iOS)
//
// ============================================================================

// Register Service Worker when page loads
document.addEventListener('DOMContentLoaded', () => {
  registerServiceWorker();
});

function registerServiceWorker() {
  // Check if browser supports service workers
  if ('serviceWorker' in navigator) {
    console.log('[PWA] Service Worker is supported');
    
    // Wait for page to fully load before registering
    window.addEventListener('load', () => {
      navigator.serviceWorker
        .register('/service-worker.js')
        .then((registration) => {
          console.log('[PWA] Service Worker registered:', registration.scope);
          
          // Check for updates
          registration.addEventListener('updatefound', () => {
            const newWorker = registration.installing;
            console.log('[PWA] Service Worker update found');
            
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                console.log('[PWA] New version available, refresh to update');
                // Could show a "Update available" notification here
              }
            });
          });
        })
        .catch((error) => {
          console.error('[PWA] Service Worker registration failed:', error);
        });
    });
    
    // Listen for messages from service worker
    navigator.serviceWorker.addEventListener('message', (event) => {
      console.log('[PWA] Message from Service Worker:', event.data);
    });
    
  } else {
    console.log('[PWA] Service Worker not supported in this browser');
  }
}

// Handle PWA installation prompt
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (event) => {
  // Prevent the mini-infobar from appearing on mobile
  event.preventDefault();
  
  // Store the event for later use
  deferredPrompt = event;
  
  console.log('[PWA] Install prompt available');
  
  // Could show a custom "Install App" button here
  // showInstallButton();
});

// Function to trigger PWA installation (can be called from a button)
function installPWA() {
  if (!deferredPrompt) {
    console.log('[PWA] Install prompt not available');
    return;
  }
  
  // Show the install prompt
  deferredPrompt.prompt();
  
  // Wait for the user to respond
  deferredPrompt.userChoice.then((choiceResult) => {
    if (choiceResult.outcome === 'accepted') {
      console.log('[PWA] User accepted install');
    } else {
      console.log('[PWA] User dismissed install');
    }
    
    // Clear the deferred prompt
    deferredPrompt = null;
  });
}

// Listen for app installed event
window.addEventListener('appinstalled', (event) => {
  console.log('[PWA] App was installed');
  deferredPrompt = null;
  
  // Could track installation analytics here
});

// Check if app is running in standalone mode (installed as PWA)
function isRunningAsPWA() {
  return window.matchMedia('(display-mode: standalone)').matches ||
         window.navigator.standalone === true; // iOS Safari
}

// Log PWA status
console.log('[PWA] Running as PWA:', isRunningAsPWA());
