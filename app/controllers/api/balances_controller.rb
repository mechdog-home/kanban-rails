# ============================================================================
# API Controller: Api::BalancesController
# ============================================================================
#
# Provides API endpoints for querying and managing AI provider balances.
#
# ENDPOINTS:
# - GET /api/balances - Get current balances from all providers
# - POST /api/balances/refresh - Force refresh and record balances
# - GET /api/balances/history - Get balance history for charting
#
# ============================================================================

module Api
  class BalancesController < ApplicationController
    # Skip CSRF for API requests
    skip_before_action :verify_authenticity_token
    
    # Allow public access to balance data (or add auth if needed)
    # before_action :authenticate_user!, except: [:index]

    # ========================================================================
    # GET /api/balances
    # ========================================================================
    #
    # Returns current balances from all providers.
    # Queries APIs in real-time for providers that support it.
    #
    # Response format:
    # {
    #   "moonshot": {
    #     "success": true,
    #     "balance": 123.45,
    #     "currency": "CNY",
    #     "name": "Moonshot (Kimi)",
    #     "supports_api": true
    #   },
    #   "openrouter": { ... },
    #   "openai": {
    #     "success": true,
    #     "balance": null,
    #     "supports_api": false,
    #     "note": "Check console..."
    #   }
    # }
    #
    def index
      # Query all providers in real-time
      @balances = BalanceService.query_all
      
      # Also get the last recorded balances from database for comparison
      @last_recorded = ApiBalanceHistory.latest_balances
      
      respond_to do |format|
        format.json { render json: { balances: @balances, last_recorded: @last_recorded } }
        format.html { render partial: 'balances/balance', locals: { balances: @balances } }
      end
    end

    # ========================================================================
    # POST /api/balances/refresh
    # ========================================================================
    #
    # Forces a refresh of all balances and records them to the database.
    # This is the endpoint called by the rake task for scheduled updates.
    #
    # Response format:
    # {
    #   "success": true,
    #   "recorded_at": "2026-02-06T20:30:00Z",
    #   "results": { ... }
    # }
    #
    def refresh
      results = BalanceService.record_balances!
      
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            recorded_at: Time.current.iso8601,
            results: results
          }
        end
        
        format.turbo_stream do
          # Return updated balance partial for Turbo Stream updates
          render turbo_stream: turbo_stream.replace(
            'api-balances',
            partial: 'balances/balance',
            locals: { balances: results }
          )
        end
        
        format.html { redirect_to root_path, notice: 'Balances refreshed successfully.' }
      end
    end

    # ========================================================================
    # GET /api/balances/history
    # ========================================================================
    #
    # Returns balance history for charting over time.
    #
    # Query parameters:
    # - provider: Filter to specific provider (optional)
    # - days: Number of days to include (default: 7)
    #
    # Response format:
    # {
    #   "moonshot": [
    #     { "timestamp": "2026-02-01T00:00:00Z", "balance": 150.0 },
    #     { "timestamp": "2026-02-02T00:00:00Z", "balance": 145.0 }
    #   ]
    # }
    #
    def history
      days = (params[:days] || 7).to_i
      days = [days, 30].min # Cap at 30 days
      
      if params[:provider].present?
        # Return history for specific provider
        history = ApiBalanceHistory.history_for(params[:provider], days)
        stats = ApiBalanceHistory.usage_stats(params[:provider], days)
        
        render json: {
          provider: params[:provider],
          days: days,
          history: history,
          stats: stats
        }
      else
        # Return history for all providers
        history = {}
        
        ApiBalanceHistory::PROVIDERS.each do |provider|
          provider_history = ApiBalanceHistory.history_for(provider, days)
          history[provider] = provider_history if provider_history.any?
        end
        
        render json: {
          days: days,
          history: history
        }
      end
    end

    # ========================================================================
    # GET /api/balances/:provider
    # ========================================================================
    #
    # Get balance for a specific provider.
    #
    def show
      provider = params[:id]
      
      unless ApiBalanceHistory::PROVIDERS.include?(provider)
        return render json: { error: 'Unknown provider' }, status: :not_found
      end
      
      result = BalanceService.query_provider(provider.to_sym)
      
      # Get last recorded from database
      last_recorded = ApiBalanceHistory.for_provider(provider).recent.first
      
      render json: {
        current: result,
        last_recorded: last_recorded&.as_json
      }
    end
  end
end
