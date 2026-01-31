# ============================================================================
# API Controller: Api::Sparky::StatusController
# ============================================================================
#
# LEARNING NOTES:
#
# This controller handles Sparky's real-time status endpoint.
# It reads from the usage-log.json file and returns context info.
#
# HOTWIRE ARCHITECTURE:
# ---------------------
# Hotwire is Rails' modern frontend framework consisting of:
# 
# 1. TURBO DRIVE - Speeds up navigation by intercepting link clicks
#    and replacing only the page body (no full reloads)
# 
# 2. TURBO FRAMES - Partial page updates within frames
#    Think of them as "page regions that can update independently"
# 
# 3. TURBO STREAMS - Real-time updates pushed from server to client
#    via WebSockets or HTTP. The server sends HTML fragments that
#    automatically update the DOM!
#
# 4. STIMULUS - A "modest JavaScript framework" for adding behavior
#    to existing HTML. Uses data-controller, data-action, data-target
#
# COMPARISON TO NODE.JS/EXPRESS:
# ------------------------------
# Express: Returns JSON, frontend polls or uses WebSocket manually
# Rails:   Can return JSON OR Turbo Streams - the client accepts both!
#          When Accept header includes 'text/vnd.turbo-stream.html',
#          we return a Turbo Stream that updates the page automatically.
#
# ============================================================================

module Api
  module Sparky
    class StatusController < ApplicationController
      # Allow cross-origin requests and skip CSRF for API
      skip_before_action :verify_authenticity_token
      
      # ==========================================================================
      # GET /api/sparky/status
      # ==========================================================================
      #
      # Returns Sparky's current status including:
      # - context_percent: Context window usage percentage
      # - model: Current AI model name
      # - is_active: Whether Sparky is currently working
      # - current_task: Active task if any
      #
      # FORMAT NEGOTIATION:
      # - If client accepts Turbo Streams, we return HTML fragments
      # - Otherwise, we return JSON (for API clients, JavaScript fetch)
      #
      def show
        # Read usage data from memory file
        usage_data = read_usage_log
        
        # Get current task (sprint or in_progress assigned to sparky)
        current_task = fetch_current_task
        
        # Build status hash
        @status = {
          timestamp: Time.current.iso8601,
          timezone: 'America/New_York',
          context_percent: usage_data[:context_percent],
          context_approx: "#{usage_data[:context_used] / 1000}k",
          model: usage_data[:model],
          is_active: active_within_last_2_minutes?(usage_data[:last_activity]),
          current_task: current_task,
          status: determine_status(current_task)
        }
        
        # Respond based on Accept header
        # Turbo Stream format: text/vnd.turbo-stream.html
        # JSON format: application/json
        respond_to do |format|
          format.json { render json: @status }
          format.turbo_stream { render turbo_stream: build_turbo_stream }
        end
      end
      
      private
      
      # ==========================================================================
      # Read and parse the usage-log.json file
      # ==========================================================================
      #
      # LEARNING NOTE: Rails provides File.read and JSON.parse
      # We use rescue blocks to handle missing files gracefully
      #
      def read_usage_log
        log_path = Rails.root.join('..', 'memory', 'usage-log.json')
        
        # Return defaults if file doesn't exist
        return default_usage_data unless File.exist?(log_path)
        
        data = JSON.parse(File.read(log_path))
        
        # Extract the most recent session
        sessions = data['sessions'] || []
        last_session = sessions.last || {}
        
        # Get last activity timestamp
        last_activity = last_session['timestamp'] ? 
                       Time.parse(last_session['timestamp']) : 
                       10.minutes.ago
        
        {
          context_percent: last_session['context_pct'] || 0,
          context_used: calculate_context_used(last_session['context_pct']),
          model: last_session['model'] || 'moonshot/kimi-k2.5',
          last_activity: last_activity
        }
      rescue JSON::ParserError, StandardError => e
        Rails.logger.error("Error reading usage log: #{e.message}")
        default_usage_data
      end
      
      # Default values when usage log is unavailable
      def default_usage_data
        {
          context_percent: 0,
          context_used: 0,
          model: 'moonshot/kimi-k2.5',
          last_activity: 10.minutes.ago
        }
      end
      
      # Calculate context tokens from percentage
      # Assuming 256k context window
      def calculate_context_used(percent)
        return 0 if percent.nil?
        (percent / 100.0 * 256_000).round
      end
      
      # Check if last activity was within 2 minutes
      def active_within_last_2_minutes?(last_activity)
        return false unless last_activity
        last_activity > 2.minutes.ago
      end
      
      # Fetch Sparky's current active task
      def fetch_current_task
        # Look for sprint tasks first (priority), then in_progress
        sprint_task = Task.for_assignee('sparky').with_status('sprint').first
        return format_task(sprint_task) if sprint_task
        
        in_progress_task = Task.for_assignee('sparky').with_status('in_progress').first
        return format_task(in_progress_task) if in_progress_task
        
        nil
      end
      
      # Format task for JSON response
      def format_task(task)
        return nil unless task
        {
          id: task.id,
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          assignee: task.assignee,
          created_at: task.created_at.iso8601,
          updated_at: task.updated_at.iso8601
        }
      end
      
      # Determine Sparky's status based on current task
      def determine_status(current_task)
        return 'idle' unless current_task
        return 'sprint' if current_task[:status] == 'sprint'
        'working'
      end
      
      # ==========================================================================
      # Build Turbo Stream response
      # ==========================================================================
      #
      # LEARNING NOTES - TURBO STREAMS:
      # -------------------------------
      # Turbo Streams let us send HTML fragments that update the DOM.
      # The server sends something like:
      #
      #   <turbo-stream action="replace" target="sparky-status">
      #     <template>
      #       <div id="sparky-status">New content here!</div>
      #     </template>
      #   </turbo-stream>
      #
      # Actions include:
      # - append: Add to end of target
      # - prepend: Add to start of target
      # - replace: Replace the target element entirely
      # - update: Replace just the content (keeps the element)
      # - remove: Remove the target element
      #
      # When Rails receives this, Turbo automatically applies the update!
      # No JavaScript needed on the frontend - it's all declarative.
      #
      # COMPARISON TO NODE.JS:
      # - Express: Send JSON, frontend manually updates DOM with JS
      # - Rails:   Can send Turbo Stream, Turbo updates DOM automatically
      #
      def build_turbo_stream
        # Replace the sparky-status element with new content
        turbo_stream.replace(
          'sparky-status',
          partial: 'sparky/status',
          locals: { status: @status }
        )
      end
    end
  end
end
