# ============================================================================
# API::UsageSnapshotsController - Record Usage Data
# ============================================================================
#
# This controller receives usage data from Sparky and stores it in the
# UsageSnapshot model for dashboard visualization.
#
# ENDPOINTS:
# - POST /api/usage_snapshots - Create a new snapshot
# - POST /api/usage_snapshots/log_usage - Record current usage
# - GET  /api/usage_snapshots - List recent snapshots
#
# ============================================================================

module Api
  class UsageSnapshotsController < ApplicationController
    before_action :authenticate_user!
    skip_before_action :verify_authenticity_token, only: [:create, :log_usage]

    # GET /api/usage_snapshots
    # Returns recent usage snapshots (last 30 days)
    def index
      snapshots = UsageSnapshot
                    .where("recorded_at >= ?", 30.days.ago)
                    .order(recorded_at: :desc)
                    .limit(100)

      render json: {
        snapshots: snapshots.map { |s| snapshot_json(s) },
        count: snapshots.count
      }
    end

    # GET /api/usage_snapshots/:id
    def show
      snapshot = UsageSnapshot.find(params[:id])
      render json: { snapshot: snapshot_json(snapshot) }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Snapshot not found" }, status: :not_found
    end

    # POST /api/usage_snapshots
    # Creates a new usage snapshot from JSON payload
    def create
      snapshot = UsageSnapshot.new(snapshot_params)
      snapshot.recorded_at ||= Time.current

      if snapshot.save
        render json: { 
          success: true, 
          snapshot: snapshot_json(snapshot),
          message: "Usage snapshot recorded successfully"
        }, status: :created
      else
        render json: { 
          success: false, 
          errors: snapshot.errors.full_messages 
        }, status: :unprocessable_entity
      end
    end

    # POST /api/usage_snapshots/log_usage
    # Convenience endpoint that creates a snapshot from current session status
    def log_usage
      # This would integrate with your session status API
      # For now, create a snapshot from params or mock data
      snapshot = UsageSnapshot.new(log_params)
      snapshot.recorded_at = Time.current

      if snapshot.save
        render json: {
          success: true,
          snapshot: snapshot_json(snapshot),
          message: "Current usage logged"
        }, status: :created
      else
        render json: {
          success: false,
          errors: snapshot.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def snapshot_params
      params.require(:usage_snapshot).permit(
        :daily_remaining,
        :weekly_remaining,
        :total_used,
        :session_count,
        :ai_model,
        :recorded_at
      )
    end

    def log_params
      {
        daily_remaining: params[:daily_remaining],
        weekly_remaining: params[:weekly_remaining],
        total_used: params[:total_used],
        session_count: params[:session_count],
        ai_model: params[:ai_model]
      }
    end

    def snapshot_json(snapshot)
      {
        id: snapshot.id,
        daily_remaining: snapshot.daily_remaining&.round(2),
        weekly_remaining: snapshot.weekly_remaining&.round(2),
        total_used: snapshot.total_used,
        session_count: snapshot.session_count,
        ai_model: snapshot.ai_model,
        recorded_at: snapshot.recorded_at&.iso8601
      }
    end
  end
end
