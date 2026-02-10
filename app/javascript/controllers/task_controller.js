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
  
  // Archive/Delete with confirmation
  // Called via: data-action="click->task#archive"
  // NOTE: This is now handled via button_to with Turbo in the view
  // This method kept for programmatic use or custom implementations
  async archive(event) {
    event.preventDefault()
    
    if (!confirm('Archive this task?')) return
    
    const url = this.deleteUrlValue || `/tasks/${this.idValue}`
    
    try {
      const response = await fetch(url, {
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
        // Success! Task archived
      } else {
        console.error('Archive failed with status:', response.status)
        alert('Failed to archive task')
      }
    } catch (error) {
      console.error('Network error archiving task:', error)
      alert('Failed to archive task - network error')
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
