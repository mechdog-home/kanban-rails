// ============================================================================
// Stimulus Controller: Task Card
// ============================================================================
//
// LEARNING NOTES:
//
// This controller handles individual task card actions.
// Demonstrates:
// - Confirmation dialogs
// - Turbo Stream responses (server sends HTML to update)
// - Fetch with Turbo
//
// TURBO STREAMS:
// Instead of returning JSON and manually updating the DOM,
// Turbo Streams let the server send HTML fragments that
// automatically update the page. Magic! ✨
//
// Server response example:
//   <turbo-stream action="remove" target="task_123"></turbo-stream>
//
// This removes the element with id="task_123" automatically!
//
// ============================================================================

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="task"
export default class extends Controller {
  // Values passed from HTML
  static values = {
    id: Number,
    deleteUrl: String
  }
  
  // Delete with confirmation
  // Called via: data-action="click->task#delete"
  async delete(event) {
    event.preventDefault()
    
    if (!confirm('Delete this task?')) return
    
    try {
      const response = await fetch(this.deleteUrlValue || `/api/tasks/${this.idValue}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html, application/json'
        }
      })
      
      if (response.ok) {
        // Check if we got a Turbo Stream response
        const contentType = response.headers.get('content-type') || ''
        const isTurboStream = contentType.includes('turbo-stream')
        
        // If Turbo Stream response, it handles DOM update automatically
        // Otherwise, remove element manually
        if (!isTurboStream) {
          this.element.remove()
        }
        // Success! Don't show any error
      } else {
        // Only show error if response was not OK
        console.error('Delete failed with status:', response.status)
        alert('Failed to delete task')
      }
    } catch (error) {
      // This catches network errors, not HTTP error responses
      console.error('Network error deleting task:', error)
      alert('Failed to delete task - network error')
    }
  }
  
  // Toggle task completion
  // Called via: data-action="click->task#toggleDone"
  async toggleDone() {
    const newStatus = this.element.dataset.status === 'done' ? 'in_progress' : 'done'
    
    try {
      const response = await fetch(`/api/tasks/${this.idValue}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ status: newStatus })
      })
      
      if (response.ok) {
        // Reload page to show updated state
        // With Turbo Streams, we could do this more elegantly
        window.location.reload()
      }
    } catch (error) {
      console.error('Error updating task:', error)
    }
  }
}
