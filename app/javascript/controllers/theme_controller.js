// ============================================================================
// Stimulus Controller: Theme Toggle
// ============================================================================
//
// LEARNING NOTES:
//
// This controller handles dark/light theme switching.
// It demonstrates:
// - Stimulus actions (data-action="click->theme#toggle")
// - LocalStorage for persistence
// - DOM manipulation in Stimulus
//
// ============================================================================

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  // Targets let us reference specific elements
  static targets = ["icon"]
  
  // Called when controller connects
  connect() {
    // Load saved theme preference
    const savedTheme = localStorage.getItem('theme') || 'dark'
    this.applyTheme(savedTheme)
  }
  
  // Toggle between dark and light
  // Called via: data-action="click->theme#toggle"
  toggle() {
    const html = document.documentElement
    const currentTheme = html.getAttribute('data-bs-theme')
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark'
    
    this.applyTheme(newTheme)
    localStorage.setItem('theme', newTheme)
  }
  
  // Apply theme to document
  applyTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme)
    
    // Update icon if target exists
    if (this.hasIconTarget) {
      this.iconTarget.className = theme === 'dark' 
        ? 'bi bi-moon-fill' 
        : 'bi bi-sun-fill'
    }
  }
}
