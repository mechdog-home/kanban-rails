# Rails Kanban Board 📋

A teaching-focused Kanban board built with Ruby on Rails, designed to help developers coming from Express/Node.js understand Rails conventions.

## Learning Goals

This app demonstrates:
- **MVC Architecture** — How Rails organizes code
- **ActiveRecord** — Rails' ORM vs Sequelize/Mongoose
- **RESTful Routes** — Convention over configuration
- **SLIM Templates** — Lightweight alternative to ERB
- **Bootstrap Integration** — Styling with simple_form

## Express vs Rails Comparison

| Concept | Express/Node.js | Ruby on Rails |
|---------|-----------------|---------------|
| Project structure | Manual setup | `rails new` generates everything |
| Routing | `app.get('/tasks', ...)` | `resources :tasks` (7 routes!) |
| ORM | Sequelize/Mongoose | ActiveRecord (built-in) |
| Migrations | Knex/manual SQL | `rails generate migration` |
| Views | EJS/Handlebars | ERB/SLIM (we use SLIM) |
| Forms | Manual HTML | simple_form gem |
| Testing | Jest/Mocha | Minitest (built-in) |

## Project Structure

```
kanban-rails/
├── app/
│   ├── controllers/        # Handle HTTP requests (like Express routes)
│   │   ├── tasks_controller.rb      # HTML views
│   │   └── api/
│   │       └── tasks_controller.rb  # JSON API
│   ├── models/             # Business logic & database (like Sequelize models)
│   │   └── task.rb
│   ├── views/              # Templates (like EJS files)
│   │   └── tasks/
│   │       ├── index.html.slim      # Kanban board
│   │       ├── new.html.slim        # New task form
│   │       ├── edit.html.slim       # Edit task form
│   │       └── _form.html.slim      # Shared form partial
│   └── helpers/            # View utility functions
│       └── tasks_helper.rb
├── config/
│   ├── routes.rb           # URL routing (like Express router)
│   └── database.yml        # Database config
├── db/
│   ├── migrate/            # Schema changes (like Knex migrations)
│   ├── schema.rb           # Current schema (auto-generated)
│   └── seeds.rb            # Sample data
└── Gemfile                 # Dependencies (like package.json)
```

## Key Files to Study

### 1. Start with the Model (`app/models/task.rb`)

```ruby
class Task < ApplicationRecord
  # Constants define valid values
  STATUSES = %w[backlog in_progress review done].freeze
  
  # Validations run before save
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  
  # Scopes are reusable query fragments
  scope :for_assignee, ->(a) { where(assignee: a) }
  scope :backlog, -> { where(status: 'backlog') }
end
```

**Express equivalent:**
```javascript
// Sequelize model
const Task = sequelize.define('Task', {
  title: { type: DataTypes.STRING, allowNull: false },
  status: { type: DataTypes.ENUM('backlog', 'in_progress', 'review', 'done') }
});
```

### 2. Then the Routes (`config/routes.rb`)

```ruby
Rails.application.routes.draw do
  resources :tasks  # Creates 7 RESTful routes automatically!
  root 'tasks#index'
end
```

**Express equivalent:**
```javascript
// You'd write each route manually
app.get('/tasks', tasksController.index);
app.get('/tasks/:id', tasksController.show);
app.post('/tasks', tasksController.create);
app.put('/tasks/:id', tasksController.update);
app.delete('/tasks/:id', tasksController.destroy);
// etc...
```

### 3. Then the Controller (`app/controllers/tasks_controller.rb`)

```ruby
class TasksController < ApplicationController
  def index
    @tasks = Task.all  # Instance vars are passed to views
    
    respond_to do |format|
      format.html  # Renders index.html.slim automatically
      format.json { render json: @tasks }
    end
  end
  
  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to tasks_path, notice: 'Created!'
    else
      render :new  # Re-render form with errors
    end
  end
  
  private
  
  # Strong parameters prevent mass assignment
  def task_params
    params.require(:task).permit(:title, :description, :assignee)
  end
end
```

### 4. Finally the Views (`app/views/tasks/index.html.slim`)

```slim
/ SLIM uses indentation instead of closing tags
h1 Tasks

- @tasks.each do |task|
  .card
    h5 = task.title
    p = task.description
```

**ERB equivalent:**
```erb
<h1>Tasks</h1>
<% @tasks.each do |task| %>
  <div class="card">
    <h5><%= task.title %></h5>
    <p><%= task.description %></p>
  </div>
<% end %>
```

## Rails Commands Cheat Sheet

```bash
# Create new app
rails new myapp --database=mysql

# Generate model with migration
rails generate model Task title:string status:string

# Generate controller
rails generate controller Tasks index show

# Database commands
rails db:create      # Create database
rails db:migrate     # Run migrations
rails db:seed        # Load seed data
rails db:reset       # Drop, create, migrate, seed

# Start server
rails server         # Default port 3000
rails server -p 3001 # Custom port

# Console (like Node REPL but with your app loaded)
rails console
> Task.all
> Task.create!(title: "Test")
> Task.where(status: 'backlog')

# Routes
rails routes         # Show all routes
```

## Database: SQLite vs MySQL

**Development** uses SQLite (zero setup):
```yaml
# config/database.yml
development:
  adapter: sqlite3
  database: db/development.sqlite3
```

**Production** uses MySQL (per RAILS_CONVENTIONS.md):
```yaml
production:
  adapter: mysql2
  url: <%= ENV['DATABASE_URL'] %>
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tasks` | List all tasks |
| GET | `/api/tasks?assignee=sparky` | Filter by assignee |
| GET | `/api/tasks/:id` | Get single task |
| POST | `/api/tasks` | Create task |
| PATCH | `/api/tasks/:id` | Update task |
| DELETE | `/api/tasks/:id` | Delete task |

## Running the App

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start server
rails server -p 3001

# Open browser
open http://localhost:3001
```

## Conventions (from RAILS_CONVENTIONS.md)

- ✅ **SLIM templates** — Cleaner than ERB
- ✅ **simple_form** — Bootstrap-compatible forms
- ✅ **MySQL for production** — SQLite for development
- ✅ **Full model names** — `task` not `t`
- ✅ **Commented code** — Explains the "why"

## Next Steps to Learn

1. **Add authentication** — Try the Devise gem
2. **Add authorization** — Try the Pundit gem
3. **Add tests** — `rails generate test_unit:model Task`
4. **Add pagination** — Try the will_paginate gem
5. **Add search** — Try the Ransack gem

---

*Built by Sparky ⚡ for MechDog 🐕 as a teaching project.*
