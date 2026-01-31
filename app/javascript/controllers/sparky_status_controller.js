// ============================================================================
// Stimulus Controller: SparkyStatus
// ============================================================================
//
// LEARNING NOTES:
//
// This controller handles live updates for Sparky's status display.
// It demonstrates:
// - Periodic polling for updates
// - Turbo Stream handling
// - Data attributes for configuration
//
// STIMULUS LIFECYCLE:
// ------------------
// 1. constructor()      → Called when controller is instantiated
// 2. initialize()       → Called once when controller is first connected
// 3. connect()          → Called every time the element appears in DOM
// 4. [actions run]      → Called when user interactions occur
// 5. disconnect()       → Called when element is removed from DOM
//
// VALUES API:
// -----------
// Stimulus has a "Values" system for passing data from HTML to JS:
// static values = { url: String, interval: Number }
// In HTML: data-sparky-status-url-value="/api/sparky/status"
// In JS:   this.urlValue gives you "/api/sparky/status"
//
// COMPARISON TO RAW JAVASCRIPT:
// -----------------------------
// Without Stimulus, you'd write:
//   document.getElementById('sparky-status').addEventListener(...)
//   setInterval(() => fetch(...), 30000)
//
// With Stimulus, it's declarative:
//   data-controller="sparky-status"
//   data-sparky-status-url-value="/api/sparky/status"
//   data-sparky-status-interval-value="30000"
//
// The controller handles setup automatically when connected!
//
// TURBO STREAMS:
// --------------
// When we fetch with Accept: text/vnd.turbo-stream.html,
// the server returns a Turbo Stream response like:
//   <turbo-stream action="replace" target="sparky-status">
//     <template>...</template>
//   </turbo-stream>
//
// Turbo automatically processes this and updates the DOM!
// We don't need to manually update elements - Turbo does it.
//
// ============================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Define value types that can be passed from HTML
  static values = {
    url: String,           // API endpoint URL
    interval: {            // Polling interval in ms (default 30s)
      type: Number,
      default: 30000
    },
    contextPercent: Number, // Current context percentage
    model: String,         // Current model name
    active: Boolean        // Whether sparky is active
  }

  // Called when controller connects to the DOM
  connect() {
    console.log('[SparkyStatus] Connected')
    
    // Start polling for updates
    this.startPolling()
    
    // Do an immediate fetch on connect
    this.fetchStatus()
  }

  // Called when controller disconnects from DOM
  disconnect() {
    console.log('[SparkyStatus] Disconnected')
    this.stopPolling()
  }

  // Start periodic polling
  startPolling() {
    // Clear any existing interval first
    this.stopPolling()
    
    // Set up new interval
    this.pollInterval = setInterval(() => {
      this.fetchStatus()
    }, this.intervalValue)
    
    console.log(`[SparkyStatus] Polling every ${this.intervalValue}ms`)
  }

  // Stop polling
  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  // Fetch status from server
  // Uses Turbo Streams for automatic DOM updates
  async fetchStatus() {
    try {
      // Request Turbo Stream format
      // This tells Rails: "Send me HTML fragments, not JSON"
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html, application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      // Check if we got a Turbo Stream response
      const contentType = response.headers.get('content-type')
      
      if (contentType && contentType.includes('turbo-stream')) {
        // Turbo Stream response - let Turbo handle the DOM update
        // The response body contains <turbo-stream> elements
        // Turbo automatically processes them!
        const html = await response.text()
        
        // Use Turbo's stream processing
        // This parses the turbo-stream elements and applies them
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const streams = doc.querySelectorAll('turbo-stream')
        
        streams.forEach(stream => {
          // Dispatch a custom event that Turbo listens for
          document.body.appendChild(stream)
        })
        
        console.log('[SparkyStatus] Updated via Turbo Stream')
      } else {
        // JSON response - would need manual update
        // This branch handles non-Turbo clients
        const data = await response.json()
        console.log('[SparkyStatus] Received JSON:', data)
        // In a real app, you'd manually update DOM elements here
      }
    } catch (error) {
      console.error('[SparkyStatus] Fetch failed:', error)
    }
  }

  // Manual refresh action (can be triggered by button)
  // Usage: data-action="click->sparky-status#refresh"
  refresh() {
    console.log('[SparkyStatus] Manual refresh triggered')
    this.fetchStatus()
  }

  // Change polling interval dynamically
  // Usage: data-action="change->sparky-status#changeInterval"
  changeInterval(event) {
    const newInterval = parseInt(event.target.value, 10)
    if (newInterval && newInterval >= 5000) {
      this.intervalValue = newInterval
      this.startPolling()
      console.log(`[SparkyStatus] Interval changed to ${newInterval}ms`)
    }
  }
}
