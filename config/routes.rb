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
  devise_for :users
  # API namespace for JSON endpoints
  # This creates routes like /api/tasks
  namespace :api do
    # Task resource routes (standard RESTful)
    resources :tasks, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :touch_last_worked
      end
    end
    
    # Stats endpoint - matches Node.js /api/stats
    # get 'stats', to: 'tasks#stats' creates GET /api/stats
    get 'stats', to: 'tasks#stats'
    
    # Sparky status endpoint - matches Node.js /api/sparky/status
    # We'll create this controller next
    namespace :sparky do
      get 'status', to: 'status#show'
    end
    
    # AI Provider Balance endpoints
    # GET /api/balances - Current balances from all providers
    # POST /api/balances/refresh - Force refresh and record to database
    # GET /api/balances/history - Balance history for charting
    resources :balances, only: [:index, :show] do
      collection do
        post :refresh
        get :history
      end
    end
  end
  
  # HTML routes for the Kanban board interface
  resources :tasks do
    # Member routes for task actions
    # POST /tasks/:id/move_left  -> moves to previous status
    # POST /tasks/:id/move_right -> moves to next status
    # POST /tasks/:id/restore    -> restores from archive
    member do
      post :move_left
      post :move_right
      post :restore
    end
    
    # Collection routes for task listings
    # GET /tasks/archived -> lists archived (soft-deleted) tasks
    collection do
      get :archived
    end
  end
  
  # Quick Notes routes - for quick ideas and scratchpad
  # Full RESTful routes: index, show, new, create, edit, update, destroy
  resources :quick_notes
  
  # User management (super_admin only, enforced by Pundit)
  resources :users
  
  # The Kanban board is our homepage
  root 'tasks#index'
  
  # Config file viewer - browse Sparky's .md files
  # GET /config - shows file browser
  # GET /config/files - JSON API for file list
  # GET /config/:file - shows specific file
  get 'config', to: 'config#index', as: :config
  get 'config/files', to: 'config#files'
  get 'config/:file', to: 'config#show', as: :config_file, constraints: { file: /[^\/]+/ }
  
  # Health check endpoint for monitoring
  get 'up' => 'rails/health#show', as: :rails_health_check
end
