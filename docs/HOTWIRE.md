# Hotwire Learning Guide 🚀

Hotwire is Rails' modern approach to building dynamic web applications with minimal JavaScript.

## What is Hotwire?

**H**TML **O**ver **T**he **W**ire - instead of sending JSON and rendering with JavaScript, Hotwire sends HTML from the server and sprinkles in JS behavior.

```
Traditional SPA:              Hotwire:
┌─────────┐                   ┌─────────┐
│ Browser │                   │ Browser │
│  React  │ ← JSON ←          │  HTML   │ ← HTML ←
│ renders │                   │ renders │
│  HTML   │                   │  done!  │
└─────────┘                   └─────────┘
```

## The Three Parts

### 1. Turbo Drive (automatic)
Speeds up page navigation without any code changes.

```html
<!-- Before: Full page reload -->
<a href="/tasks">View Tasks</a>

<!-- After (automatic): AJAX fetch, update body -->
<a href="/tasks">View Tasks</a>  <!-- Same HTML, but faster! -->
```

**How it works:**
1. User clicks link
2. Turbo intercepts the click
3. Fetches new page via AJAX
4. Replaces `<body>` content
5. Updates browser URL

**Disable for specific links:**
```html
<a href="/file.pdf" data-turbo="false">Download PDF</a>
```

### 2. Turbo Frames (partial updates)
Update only part of the page.

```html
<!-- In your layout -->
<turbo-frame id="task_form">
  <%= render 'form' %>
</turbo-frame>

<!-- When form submits, only this frame updates -->
```

**Example: Inline editing**
```slim
/ Show mode
turbo-frame id="task_#{task.id}"
  .card
    h5 = task.title
    = link_to 'Edit', edit_task_path(task)

/ Edit mode (replaces the frame)
turbo-frame id="task_#{task.id}"
  = form_for task do |f|
    = f.text_field :title
    = f.submit 'Save'
```

### 3. Turbo Streams (real-time updates)
Server pushes HTML updates to the browser.

**Actions available:**
```html
<!-- Append to a container -->
<turbo-stream action="append" target="tasks">
  <template><div class="task">New task!</div></template>
</turbo-stream>

<!-- Prepend to a container -->
<turbo-stream action="prepend" target="tasks">...</turbo-stream>

<!-- Replace an element -->
<turbo-stream action="replace" target="task_123">...</turbo-stream>

<!-- Update contents (keeps element) -->
<turbo-stream action="update" target="task_123">...</turbo-stream>

<!-- Remove an element -->
<turbo-stream action="remove" target="task_123"></turbo-stream>
```

**In Rails controller:**
```ruby
def destroy
  @task.destroy
  
  respond_to do |format|
    format.turbo_stream  # Renders destroy.turbo_stream.erb
    format.html { redirect_to tasks_path }
  end
end
```

**destroy.turbo_stream.erb:**
```erb
<%= turbo_stream.remove @task %>
```

## Stimulus (JavaScript Sprinkles)

Stimulus adds JavaScript behavior to HTML elements.

### Basic Structure

```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Targets: elements you want to reference
  static targets = ["output"]
  
  // Values: data from HTML
  static values = { name: String }
  
  // Called when controller connects
  connect() {
    console.log("Hello controller connected!")
  }
  
  // Action method
  greet() {
    this.outputTarget.textContent = `Hello, ${this.nameValue}!`
  }
}
```

```html
<div data-controller="hello" data-hello-name-value="World">
  <button data-action="click->hello#greet">Greet</button>
  <span data-hello-target="output"></span>
</div>
```

### Naming Convention

| HTML | JavaScript |
|------|------------|
| `data-controller="task-card"` | `task_card_controller.js` |
| `data-task-card-target="title"` | `this.titleTarget` |
| `data-task-card-id-value="123"` | `this.idValue` |
| `data-action="click->task-card#delete"` | `delete()` method |

### Lifecycle Callbacks

```javascript
export default class extends Controller {
  initialize() {
    // Called once when controller is first instantiated
  }
  
  connect() {
    // Called each time controller connects to DOM
    // Like componentDidMount in React
  }
  
  disconnect() {
    // Called when controller disconnects from DOM
    // Like componentWillUnmount in React
  }
}
```

### Targets

```javascript
static targets = ["button", "input", "output"]

// Single target (first match)
this.buttonTarget       // Element
this.hasButtonTarget    // Boolean

// Multiple targets (all matches)
this.buttonTargets      // Array of elements
```

### Values

```javascript
static values = {
  count: { type: Number, default: 0 },
  url: String,
  enabled: Boolean,
  items: Array,
  config: Object
}

// Access
this.countValue     // Get
this.countValue = 5 // Set

// Changed callback
countValueChanged(newValue, oldValue) {
  console.log(`Count changed from ${oldValue} to ${newValue}`)
}
```

### Actions

```html
<!-- Click event -->
<button data-action="click->controller#method">

<!-- Other events -->
<input data-action="input->search#query">
<form data-action="submit->form#save">
<div data-action="mouseenter->tooltip#show mouseleave->tooltip#hide">

<!-- With options -->
<a data-action="click->nav#follow:prevent">  <!-- preventDefault -->
<input data-action="keydown.enter->form#submit">  <!-- Only Enter key -->
```

## Comparison: React vs Stimulus

### Counter Example

**React:**
```jsx
function Counter() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}
```

**Stimulus:**
```html
<div data-controller="counter" data-counter-count-value="0">
  <p>Count: <span data-counter-target="display">0</span></p>
  <button data-action="click->counter#increment">+</button>
</div>
```

```javascript
export default class extends Controller {
  static targets = ["display"]
  static values = { count: Number }
  
  increment() {
    this.countValue++
    this.displayTarget.textContent = this.countValue
  }
}
```

**Key difference:** In React, JavaScript creates HTML. In Stimulus, HTML is primary, JavaScript enhances it.

## When to Use Each

| Use Case | Solution |
|----------|----------|
| Faster page loads | Turbo Drive (automatic) |
| Inline editing | Turbo Frames |
| Real-time updates | Turbo Streams + ActionCable |
| Form validation | Stimulus controller |
| Drag and drop | Stimulus + library |
| Complex state | Consider React/Vue |

## Files in This Project

```
app/javascript/controllers/
├── application.js          # Stimulus setup
├── index.js               # Auto-loads controllers
├── hello_controller.js    # Example controller
├── sortable_controller.js # Drag-and-drop
├── theme_controller.js    # Dark/light toggle
└── task_controller.js     # Task card actions
```

## Resources

- [Hotwire.dev](https://hotwired.dev/) - Official docs
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Better Stimulus](https://www.betterstimulus.com/) - Patterns & practices

---

*Hotwire lets you build modern, dynamic web apps while keeping your code simple and your sanity intact!* ⚡
