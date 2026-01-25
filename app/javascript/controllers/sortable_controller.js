// ============================================================================
// Stimulus Controller: Sortable
// ============================================================================
//
// LEARNING NOTES:
//
// This is a Stimulus controller - a lightweight way to add JavaScript behavior
// to HTML elements. Stimulus is part of Hotwire, Rails' modern frontend stack.
//
// KEY CONCEPTS:
// - Controllers are connected to HTML via data-controller="sortable"
// - Targets let you reference DOM elements: data-sortable-target="column"
// - Values pass data from HTML: data-sortable-url-value="/api/tasks"
// - Actions bind events: data-action="click->sortable#doSomething"
//
// HOTWIRE STACK:
// - Turbo Drive: Speeds up navigation (no full page reloads)
// - Turbo Frames: Update parts of the page independently
// - Turbo Streams: Real-time updates via WebSocket or HTTP
// - Stimulus: Sprinkle JavaScript behavior on HTML
//
// COMPARISON TO REACT/VUE:
// - React/Vue: JavaScript renders HTML (component-based)
// - Stimulus: HTML is primary, JavaScript enhances it
// - Stimulus controllers are ~10-50 lines, not thousands
//
// ============================================================================

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sortable"
export default class extends Controller {
  // Define targets - elements we want to reference
  // Access via this.columnTargets (array) or this.columnTarget (first)
  static targets = ["column"]
  
  // Define values - data passed from HTML
  // Access via this.apiUrlValue
  static values = {
    apiUrl: { type: String, default: "/api/tasks" }
  }
  
  // ========================================================================
  // LIFECYCLE CALLBACKS
  // ========================================================================
  
  // Called when controller is connected to the DOM
  // Like componentDidMount in React
  connect() {
    console.log("Sortable controller connected!")
    this.initializeSortable()
  }
  
  // Called when controller is disconnected from DOM
  // Like componentWillUnmount in React
  disconnect() {
    console.log("Sortable controller disconnected")
    // Cleanup if needed
  }
  
  // ========================================================================
  // METHODS
  // ========================================================================
  
  initializeSortable() {
    // Check if Sortable library is loaded
    if (typeof Sortable === 'undefined') {
      console.error("Sortable.js not loaded!")
      return
    }
    
    // Initialize Sortable on each column target
    this.columnTargets.forEach(column => {
      new Sortable(column, {
        group: 'tasks',           // Allow dragging between columns
        animation: 150,           // Smooth animation
        ghostClass: 'dragging',   // CSS class for drag ghost
        
        // Called when drag ends
        onEnd: (evt) => this.handleDragEnd(evt)
      })
    })
    
    console.log(`Initialized ${this.columnTargets.length} sortable columns`)
  }
  
  // Handle drag completion - update task via API
  handleDragEnd(evt) {
    const taskCard = evt.item
    const taskId = taskCard.dataset.id
    const newStatus = evt.to.dataset.status
    const newAssignee = evt.to.dataset.assignee
    
    console.log(`Moving task ${taskId} to ${newStatus} (${newAssignee})`)
    
    // Update via API
    this.updateTask(taskId, { status: newStatus, assignee: newAssignee })
  }
  
  // API call to update task
  async updateTask(taskId, data) {
    try {
      const response = await fetch(`${this.apiUrlValue}/${taskId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(data)
      })
      
      if (!response.ok) throw new Error('Update failed')
      
      const task = await response.json()
      console.log('Task updated:', task)
      
      // Optional: Show success notification
      this.showNotification('Task moved successfully', 'success')
      
    } catch (error) {
      console.error('Error updating task:', error)
      this.showNotification('Failed to move task', 'danger')
      
      // Reload page to restore correct state
      // Turbo.visit(window.location.href)
    }
  }
  
  // Show Bootstrap toast notification
  showNotification(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `toast align-items-center text-bg-${type} border-0`
    toast.setAttribute('role', 'alert')
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `
    
    // Add to toast container (create if doesn't exist)
    let container = document.querySelector('.toast-container')
    if (!container) {
      container = document.createElement('div')
      container.className = 'toast-container position-fixed bottom-0 end-0 p-3'
      document.body.appendChild(container)
    }
    container.appendChild(toast)
    
    // Show toast
    const bsToast = new bootstrap.Toast(toast)
    bsToast.show()
    
    // Remove after hidden
    toast.addEventListener('hidden.bs.toast', () => toast.remove())
  }
}
