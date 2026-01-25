# ============================================================================
# Routes Configuration
# ============================================================================
#
# LEARNING NOTES:
#
# This file defines all URL routes for the application.
# Routes map URLs to controller actions.
#
# KEY CONCEPTS:
# - `resources` creates RESTful routes (index, show, new, create, edit, update, destroy)
# - `root` sets the homepage
# - Routes are matched in order, first match wins
#
# COMPARISON TO EXPRESS:
# - Express: app.get('/tasks', tasksController.index)
# - Rails: resources :tasks (creates all 7 RESTful routes at once)
#
# Run `rails routes` to see all defined routes.
#
# ============================================================================

Rails.application.routes.draw do
  # API namespace for JSON endpoints
  # This creates routes like /api/tasks
  namespace :api do
    resources :tasks, only: [:index, :show, :create, :update, :destroy]
  end
  
  # HTML routes for the Kanban board interface
  resources :tasks
  
  # The Kanban board is our homepage
  root 'tasks#index'
  
  # Health check endpoint for monitoring
  get 'up' => 'rails/health#show', as: :rails_health_check
end
