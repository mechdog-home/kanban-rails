// ============================================================================
// Stimulus Controller: Sortable (Drag-and-Drop Kanban Columns)
// ============================================================================
//
// LEARNING NOTES:
//
// This is a Stimulus controller — a lightweight way to add JavaScript behavior
// to HTML elements. Stimulus is part of Hotwire, Rails' modern frontend stack.
//
// KEY CONCEPTS:
// - Controllers connect to HTML via data-controller="sortable"
// - Targets let you reference DOM elements: data-sortable-target="column"
// - Values pass data from HTML: data-sortable-api-url-value="/api/tasks"
// - Actions bind events: data-action="click->sortable#doSomething"
//
// HOW THIS CONTROLLER WORKS:
// 1. HTML has a container with data-controller="sortable"
// 2. Inside it, multiple columns have data-sortable-target="column"
// 3. Each column has data-status and data-assignee attributes
// 4. When Stimulus connects this controller, it initializes Sortable.js
//    on every column target, allowing cards to be dragged between them
// 5. When a card is dropped, we send a PATCH request to update the task
//
// HOTWIRE STACK (how the pieces fit together):
// - Turbo Drive:  Speeds up navigation (no full page reloads)
// - Turbo Frames: Update parts of the page independently
// - Turbo Streams: Real-time updates via WebSocket or HTTP
// - Stimulus:     Sprinkle JavaScript behavior on server-rendered HTML
//
// COMPARISON TO REACT/VUE:
// - React/Vue: JavaScript renders HTML (component-based, client-side state)
// - Stimulus:  HTML is primary, JS enhances it (server-side state)
// - Stimulus controllers are ~10-50 lines, not thousands
// - State lives in the DOM (data attributes), not in JS variables
//
// WHY SORTABLE.JS?
// - Sortable.js is a lightweight drag-and-drop library (~10KB)
// - It works with plain DOM elements (no framework needed)
// - The `group` option allows dragging between multiple lists
// - Perfect match for Stimulus: HTML-first, JS-enhanced
//
// IMPORTMAP CONNECTION:
// - We pin "sortablejs" in config/importmap.rb to a CDN URL
// - Then import it here with: import Sortable from "sortablejs"
// - No npm install, no node_modules, no build step!
// - Rails' importmap translates "sortablejs" → the CDN URL in the browser
//
// ============================================================================

import { Controller } from "@hotwired/stimulus"

// Import Sortable.js via importmap
// LEARNING NOTE: This import works because we pinned "sortablejs" in
// config/importmap.rb. The browser's native import map resolves
// "sortablejs" to the CDN URL we specified. No bundler needed!
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
export default class extends Controller {

  // ==========================================================================
  // STIMULUS DECLARATIONS
  // ==========================================================================

  // Define targets — elements we want to reference from JavaScript
  // LEARNING NOTE: For each target name, Stimulus creates:
  //   this.columnTarget  → first matching element (or error if none)
  //   this.columnTargets → array of ALL matching elements
  //   this.hasColumnTarget → boolean, true if at least one exists
  // HTML side: <div data-sortable-target="column">
  static targets = ["column"]

  // Define values — data passed from HTML to JavaScript
  // LEARNING NOTE: Values are typed and have defaults. Stimulus reads them
  // from data attributes: data-sortable-api-url-value="/api/tasks"
  // Access via: this.apiUrlValue (camelCase, "Value" suffix added automatically)
  static values = {
    apiUrl: { type: String, default: "/api/tasks" }
  }

  // ==========================================================================
  // LIFECYCLE CALLBACKS
  // ==========================================================================
  //
  // Stimulus controllers have lifecycle methods, similar to React:
  //   connect()    → componentDidMount (element added to DOM)
  //   disconnect() → componentWillUnmount (element removed from DOM)
  //
  // WHEN DOES connect() RUN?
  // - When the page first loads and the element is in the DOM
  // - When Turbo Drive navigates to a page containing this element
  // - When a Turbo Frame or Stream adds this element dynamically
  // Stimulus handles all of these automatically!
  //

  connect() {
    console.log("🎯 Sortable controller connected!")
    this.initializeSortable()
  }

  disconnect() {
    // LEARNING NOTE: Always clean up in disconnect()!
    // If Turbo navigates away and back, connect() runs again.
    // Without cleanup, you'd get duplicate Sortable instances.
    console.log("🔌 Sortable controller disconnected")
    this.destroySortableInstances()
  }

  // ==========================================================================
  // SORTABLE INITIALIZATION
  // ==========================================================================

  initializeSortable() {
    // LEARNING NOTE: this.columnTargets is an array of all elements with
    // data-sortable-target="column". Stimulus finds them automatically.
    // We loop through and create a Sortable instance for each column.

    // Store instances so we can destroy them in disconnect()
    this.sortableInstances = []

    this.columnTargets.forEach(column => {
      const instance = new Sortable(column, {
        // GROUP: All columns share the same group name, so cards can
        // be dragged FROM any column TO any other column.
        // Without this, cards could only be reordered within one column.
        group: "kanban-tasks",

        // ANIMATION: Smooth 150ms transition when cards move
        animation: 150,

        // GHOST CLASS: CSS class added to the "ghost" element (the
        // semi-transparent copy that follows your cursor while dragging).
        // We style this in CSS to show it's being dragged.
        ghostClass: "dragging",

        // DRAG CLASS: CSS class added to the element being dragged
        // (the original in its source position)
        dragClass: "drag-active",

        // CHOSEN CLASS: CSS class added when element is clicked/touched
        // but before dragging starts
        chosenClass: "drag-chosen",

        // HANDLE: Only allow dragging from the card header area
        // If omitted, the entire card is draggable (which is fine for us)
        // handle: ".card-header",

        // FORCE FALLBACK: Use JS-based drag instead of HTML5 drag API
        // HTML5 drag is buggy across browsers; this is more reliable
        forceFallback: true,

        // FALLBACK CLASS: Class added to the clone during fallback drag
        fallbackClass: "sortable-fallback",

        // ================================================================
        // EVENT CALLBACKS
        // ================================================================
        //
        // Sortable.js fires events during the drag lifecycle:
        //   onStart → drag begins
        //   onEnd   → drag ends (card dropped)
        //   onAdd   → card added to this column (from another)
        //   onRemove → card removed from this column (to another)
        //
        // We use arrow functions (=>) so `this` refers to our Stimulus
        // controller, not the Sortable instance.
        //

        onEnd: (evt) => this.handleDragEnd(evt)
      })

      this.sortableInstances.push(instance)
    })

    console.log(`✅ Initialized ${this.sortableInstances.length} sortable columns`)
  }

  // Clean up Sortable instances to prevent memory leaks
  destroySortableInstances() {
    if (this.sortableInstances) {
      this.sortableInstances.forEach(instance => instance.destroy())
      this.sortableInstances = []
    }
  }

  // ==========================================================================
  // DRAG EVENT HANDLER
  // ==========================================================================
  //
  // LEARNING NOTE: This is the core of the drag-and-drop integration.
  // When a card is dropped into a new column, we need to:
  // 1. Read the new column's status and assignee from data attributes
  // 2. Send a PATCH request to the Rails API to update the task
  // 3. Show feedback (success/error) to the user
  //
  // DATA FLOW:
  //   User drags card → Sortable fires onEnd → we read DOM data →
  //   fetch() sends PATCH to /api/tasks/:id → Rails updates DB →
  //   JSON response confirms → we show a toast notification
  //
  // COMPARISON TO RAILS FORMS:
  // - Rails form: User fills in fields → submits → server processes
  // - Drag-and-drop: User drags → JS reads new position → API call
  // - Same result (task updated), different UX!
  //

  handleDragEnd(evt) {
    // evt.item = the DOM element that was dragged (the task card)
    // evt.to   = the column it was dropped into
    // evt.from = the column it came from

    const taskCard  = evt.item
    const taskId    = taskCard.dataset.id
    const newStatus = evt.to.dataset.status
    const newAssignee = evt.to.dataset.assignee

    // LEARNING NOTE: dataset is the JavaScript API for reading data-* attributes
    // taskCard.dataset.id reads data-id="123" → "123"
    // evt.to.dataset.status reads data-status="in_progress" → "in_progress"

    // Skip API call if nothing changed (dropped back in same spot)
    if (evt.from === evt.to && evt.oldIndex === evt.newIndex) {
      console.log("📌 Card dropped in same position, no update needed")
      return
    }

    console.log(`🚚 Moving task ${taskId} → status: ${newStatus}, assignee: ${newAssignee}`)

    // Update the card's data attributes to reflect the new state
    // This keeps the DOM in sync even before the API responds
    taskCard.dataset.status = newStatus

    // Update the column counts in the UI
    this.updateColumnCounts()

    // Send the update to the Rails API
    this.updateTask(taskId, { status: newStatus, assignee: newAssignee })
  }

  // ==========================================================================
  // API COMMUNICATION
  // ==========================================================================
  //
  // LEARNING NOTE: This is how JavaScript talks to Rails!
  //
  // We use the Fetch API (built into browsers) to make HTTP requests.
  // This is similar to how you'd use axios or jQuery.ajax, but it's
  // built-in — no library needed.
  //
  // THE REQUEST:
  // - Method: PATCH (partial update — Rails convention)
  // - URL: /api/tasks/123 (RESTful route)
  // - Headers: Tell Rails we're sending/expecting JSON
  // - Body: JSON with the fields to update
  //
  // THE RESPONSE:
  // - 200 OK + JSON body = success (Rails sends back updated task)
  // - 422 Unprocessable = validation error
  // - 404 Not Found = task doesn't exist
  //
  // ASYNC/AWAIT:
  // - `async` marks this as an asynchronous function
  // - `await` pauses execution until the Promise resolves
  // - This makes async code read like synchronous code
  // - Without await: fetch().then().then().catch() (callback hell)
  //

  async updateTask(taskId, data) {
    try {
      const response = await fetch(`${this.apiUrlValue}/${taskId}`, {
        method: "PATCH",
        headers: {
          // Tell Rails we're sending JSON in the request body
          "Content-Type": "application/json",
          // Tell Rails we want JSON back in the response
          "Accept": "application/json"
        },
        // Convert our JS object to a JSON string for the request body
        // Rails will parse this back into params on the server side
        body: JSON.stringify(data)
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const task = await response.json()
      console.log("✅ Task updated:", task)

      // Show success feedback
      this.showNotification("Task moved successfully!", "success")

    } catch (error) {
      console.error("❌ Error updating task:", error)
      this.showNotification("Failed to move task. Try refreshing.", "danger")

      // LEARNING NOTE: On error, we could reload to restore correct state:
      // import { Turbo } from "@hotwired/turbo-rails"
      // Turbo.visit(window.location.href)
      // But that's jarring UX. Better to show an error and let user retry.
    }
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  // Update the task count badges in each column header
  // LEARNING NOTE: This is "optimistic UI" — we update the display
  // immediately without waiting for the server response.
  // If the server update fails, the counts might be wrong until
  // the next page load, but the UX feels snappier.
  updateColumnCounts() {
    this.columnTargets.forEach(column => {
      // Count the task cards currently in this column
      const cardCount = column.querySelectorAll(".task-card").length
      // Find the badge element in the column header
      // LEARNING NOTE: closest() walks UP the DOM tree to find a parent
      // querySelector() walks DOWN to find a child
      const header = column.querySelector(".column-count")
      if (header) {
        header.textContent = cardCount
      }
    })
  }

  // Show a Bootstrap toast notification
  //
  // LEARNING NOTE: This creates DOM elements with JavaScript.
  // In Rails views, we'd write HTML in .slim templates.
  // But for dynamic notifications that appear after user actions,
  // creating elements in JS is the right approach.
  //
  // document.createElement() → creates a new HTML element
  // element.className       → sets CSS classes
  // element.innerHTML       → sets the HTML content inside
  // element.appendChild()   → adds a child element
  //
  showNotification(message, type = "info") {
    // Create the toast element
    const toast = document.createElement("div")
    toast.className = `toast align-items-center text-bg-${type} border-0`
    toast.setAttribute("role", "alert")
    toast.setAttribute("aria-live", "assertive")
    toast.setAttribute("aria-atomic", "true")
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto"
                data-bs-dismiss="toast" aria-label="Close"></button>
      </div>
    `

    // Find or create the toast container
    // LEARNING NOTE: We use a fixed-position container so toasts
    // appear in the bottom-right corner regardless of scroll position
    let container = document.querySelector(".toast-container")
    if (!container) {
      container = document.createElement("div")
      container.className = "toast-container position-fixed bottom-0 end-0 p-3"
      container.style.zIndex = "1080"  // Above Bootstrap modals
      document.body.appendChild(container)
    }
    container.appendChild(toast)

    // Initialize and show the Bootstrap Toast component
    // LEARNING NOTE: Bootstrap's JS components are initialized by
    // creating new instances: new bootstrap.Toast(element)
    // This is similar to how Stimulus controllers are connected to elements
    const bsToast = new bootstrap.Toast(toast, { delay: 3000 })
    bsToast.show()

    // Clean up the DOM after the toast is hidden
    toast.addEventListener("hidden.bs.toast", () => toast.remove())
  }
}
