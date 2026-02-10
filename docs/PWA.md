# Kanban Board PWA Documentation

## Overview

The Kanban Board is now a Progressive Web App (PWA) that can be installed on Windows, Mac, iOS, and Android devices. This provides offline support, native app-like experience, and quick access from the home screen.

## Features

- **Offline Support**: Access your tasks even without internet connection
- **Installable**: Add to home screen/desktop as a standalone app
- **Responsive**: Works on all screen sizes
- **Background Sync**: Task updates sync when connection returns
- **Native Feel**: Full-screen experience without browser chrome

## Installation Guide

### Windows (Chrome/Edge)

1. Open the Kanban Board in Chrome or Edge
2. Look for the **Install icon** (➕) in the address bar
3. Click "Install Kanban Board"
4. The app will open in its own window and appear in:
   - Start Menu
   - Desktop shortcut (optional)
   - Taskbar (when pinned)

### macOS (Chrome/Edge)

1. Open the Kanban Board in Chrome or Edge
2. Chrome: Click the **Install icon** in the address bar
3. Edge: Menu (⋯) → Apps → Install this site as an app
4. The app opens in its own window
5. Find it in:
   - Applications folder
   - Launchpad
   - Dock (when dragged there)

### iOS (Safari)

1. Open the Kanban Board in Safari
2. Tap the **Share button** (square with arrow up)
3. Scroll down and tap **"Add to Home Screen"**
4. Tap **"Add"** in the top right
5. The app icon appears on your home screen

### Android (Chrome)

1. Open the Kanban Board in Chrome
2. Look for the **"Add to Home Screen"** banner at the bottom
3. Or tap the menu (⋮) → "Add to Home Screen"
4. The app icon appears on your home screen

## Technical Details

### Files Added

| File | Purpose |
|------|---------|
| `public/manifest.json` | PWA manifest with app metadata, icons, theme |
| `public/service-worker.js` | Service worker for offline caching and background sync |
| `app/javascript/pwa.js` | Service worker registration and PWA event handling |
| `app/views/layouts/application.html.slim` | Updated with manifest link and theme-color meta |

### Service Worker Strategies

1. **Static Assets**: Cache First
   - CSS, JavaScript, images are cached
   - Served from cache, updated in background
   
2. **API Requests**: Network First
   - Task data fetched from network
   - Falls back to cache when offline
   - Updates cache with fresh data

### Browser Support

| Browser | Support Level |
|---------|--------------|
| Chrome (Win/Mac/Android) | ✅ Full support |
| Edge (Win/Mac) | ✅ Full support |
| Safari (iOS/macOS) | ✅ Full support |
| Firefox | ⚠️ Limited (no install prompt) |

## Troubleshooting

### Install Button Not Appearing

- Ensure you're using HTTPS (required for PWAs)
- Check that the manifest.json is accessible
- Verify service worker registered (check DevTools → Application → Service Workers)

### Offline Mode Not Working

1. First visit must be online to cache assets
2. Check DevTools → Application → Cache Storage
3. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R) may be needed

### Updates Not Showing

Service workers cache aggressively. To force update:
- Close and reopen the app
- Or: DevTools → Application → Service Workers → "Update"
- Or: DevTools → Application → Clear storage → Clear site data

## Development Notes

### Testing PWA Features

```bash
# Chrome DevTools
# 1. Open DevTools (F12)
# 2. Go to Application tab
# 3. Check:
#    - Manifest (valid JSON, icons load)
#    - Service Workers (registered and active)
#    - Cache Storage (assets cached)
# 4. Go to Lighthouse tab → Run PWA audit
```

### Updating the Service Worker

1. Increment `CACHE_NAME` version in `service-worker.js`
2. Deploy changes
3. Existing users will get the new version on next visit

### Adding New Icons

1. Generate icons in sizes: 192x192, 512x512 (regular and maskable)
2. Place in `public/` directory
3. Update `manifest.json` icons array
4. For maskable icons, use [maskable.app](https://maskable.app) to verify

## Future Enhancements

- [ ] Push notifications for task reminders
- [ ] Background sync for offline task updates
- [ ] App badges for task count
- [ ] Share target (receive shared URLs as tasks)
- [ ] Shortcuts for common actions

## References

- [MDN PWA Guide](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [Google PWA Checklist](https://web.dev/pwa-checklist/)
- [Web App Manifest Spec](https://w3c.github.io/manifest/)
