// ============================================================================
// Stimulus Controller: Balance
// ============================================================================
//
// Handles auto-refresh of AI provider balance displays.
// Polls the API periodically and updates the display.
//
// LEARNING NOTES:
//
// This controller follows the same pattern as sparky_status_controller.js
// but with simplified functionality for balance display.
//
// DATA ATTRIBUTES:
// - data-balance-url-value: API endpoint URL (default: /api/balances)
// - data-balance-refresh-interval-value: Polling interval in ms (default: 5min)
//
// ACTIONS:
// - click->balance#refresh: Manual refresh button
//
// ============================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: { type: String, default: "/api/balances" },
    refreshUrl: { type: String, default: "/api/balances/refresh" },
    refreshInterval: { type: Number, default: 300000 } // 5 minutes
  }

  static targets = ["lastUpdated"]

  connect() {
    console.log('[Balance] Connected')
    this.startAutoRefresh()
  }

  disconnect() {
    console.log('[Balance] Disconnected')
    this.stopAutoRefresh()
  }

  // Start periodic auto-refresh
  startAutoRefresh() {
    this.stopAutoRefresh()
    
    if (this.refreshIntervalValue > 0) {
      this.refreshTimer = setInterval(() => {
        this.refresh()
      }, this.refreshIntervalValue)
      
      console.log(`[Balance] Auto-refresh every ${this.refreshIntervalValue}ms`)
    }
  }

  // Stop auto-refresh
  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  // Manual refresh action - queries live APIs and updates display
  async refresh() {
    console.log('[Balance] Refreshing balances from live APIs...')
    
    // Show loading state
    const refreshButton = this.element.querySelector('[data-action="click->balance#refresh"] i')
    if (refreshButton) {
      refreshButton.classList.add('spin-animation')
    }
    
    try {
      // Call the refresh endpoint to query live APIs
      const response = await fetch(this.refreshUrlValue, {
        method: 'POST',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const contentType = response.headers.get('content-type') || ''
      
      if (contentType.includes('turbo-stream')) {
        // Turbo Stream response - let Turbo handle the update
        const html = await response.text()
        // Insert and process Turbo Streams
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const streams = doc.querySelectorAll('turbo-stream')
        streams.forEach(stream => {
          document.body.appendChild(stream)
          setTimeout(() => stream.remove(), 100)
        })
        console.log('[Balance] Updated via Turbo Stream')
      } else if (contentType.includes('text/html')) {
        // HTML response - replace the entire balance section
        const html = await response.text()
        this.element.outerHTML = html
        console.log('[Balance] Updated via HTML response')
      } else {
        // JSON response
        const data = await response.json()
        this.updateTimestamp(data.recorded_at)
        // Reload to get updated partial
        window.location.reload()
        console.log('[Balance] Updated via JSON response')
      }
    } catch (error) {
      console.error('[Balance] Refresh failed:', error)
      alert('Failed to refresh balances. Please try again.')
    } finally {
      // Remove loading state
      if (refreshButton) {
        refreshButton.classList.remove('spin-animation')
      }
    }
  }

  // Update the timestamp display
  updateTimestamp(recordedAt) {
    if (!recordedAt) return
    
    const timestampEl = this.element.querySelector('.last-updated')
    if (timestampEl) {
      const date = new Date(recordedAt)
      const formatted = date.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit',
        second: '2-digit'
      })
      timestampEl.textContent = `Updated ${formatted}`
    }
  }

  // Update display from JSON data
  updateDisplay(data) {
    // Update the last updated timestamp
    if (this.hasLastUpdatedTarget) {
      this.lastUpdatedTarget.textContent = 'Updated just now'
    }
    
    // Update timestamp if available
    if (data.recorded_at) {
      this.updateTimestamp(data.recorded_at)
    }
    
    // In a full implementation, we'd update individual balance cells
    // For now, the HTML response approach is simpler and more robust
  }

  // Change refresh interval (can be called from a select dropdown)
  changeInterval(event) {
    const newInterval = parseInt(event.target.value, 10)
    if (newInterval && newInterval >= 10000) { // Min 10 seconds
      this.refreshIntervalValue = newInterval
      this.startAutoRefresh()
      console.log(`[Balance] Interval changed to ${newInterval}ms`)
    }
  }
}
