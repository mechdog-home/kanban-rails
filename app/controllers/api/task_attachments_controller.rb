# ============================================================================
# API Controller: Api::TaskAttachmentsController
# ============================================================================
#
# Handles file uploads and downloads for task attachments.
#
# API ENDPOINTS:
# - GET    /api/tasks/:task_id/attachments     -> List attachments for a task
# - POST   /api/tasks/:task_id/attachments     -> Upload new attachment
# - GET    /api/attachments/:id                -> Get attachment metadata
# - DELETE /api/attachments/:id                -> Delete attachment
# - GET    /api/attachments/:id/download       -> Download file
# - GET    /api/attachments/:id/view           -> View file (inline)
#
# ============================================================================

module Api
  class TaskAttachmentsController < ApplicationController
    # Skip CSRF for API requests
    skip_before_action :verify_authenticity_token
    
    # Find task for nested routes
    before_action :set_task, only: [:index, :create]
    
    # Find attachment for member routes
    before_action :set_attachment, only: [:show, :destroy, :download, :view]

    # ========================================================================
    # GET /api/tasks/:task_id/attachments
    # ========================================================================
    #
    # List all attachments for a specific task.
    #
    def index
      attachments = @task.attachments.recent
      
      render json: attachments.map { |att| attachment_json(att) }
    end

    # ========================================================================
    # POST /api/tasks/:task_id/attachments
    # ========================================================================
    #
    # Upload a new file attachment to a task.
    #
    # Request: multipart/form-data
    # - file: The file to upload (required)
    # - description: Optional description/caption
    #
    def create
      attachment = @task.attachments.new(attachment_params)
      
      # Attach the uploaded file
      if params[:file].present?
        attachment.file.attach(params[:file])
      end
      
      if attachment.save
        render json: attachment_json(attachment), status: :created
      else
        render json: { errors: attachment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # ========================================================================
    # GET /api/attachments/:id
    # ========================================================================
    #
    # Get attachment metadata.
    #
    def show
      render json: attachment_json(@attachment)
    end

    # ========================================================================
    # DELETE /api/attachments/:id
    # ========================================================================
    #
    # Delete an attachment (removes file and record).
    #
    def destroy
      @attachment.destroy
      head :no_content
    end

    # ========================================================================
    # GET /api/attachments/:id/download
    # ========================================================================
    #
    # Download the attached file (disposition: attachment).
    #
    def download
      redirect_to @attachment.file.url(disposition: 'attachment') and return
    rescue => e
      render json: { error: "File not available: #{e.message}" }, status: :not_found
    end

    # ========================================================================
    # GET /api/attachments/:id/view
    # ========================================================================
    #
    # View the attached file inline (for images, PDFs).
    #
    def view
      redirect_to @attachment.file.url(disposition: 'inline') and return
    rescue => e
      render json: { error: "File not available: #{e.message}" }, status: :not_found
    end

    private

    def set_task
      @task = Task.find(params[:task_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Task not found' }, status: :not_found
    end

    def set_attachment
      @attachment = TaskAttachment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Attachment not found' }, status: :not_found
    end

    def attachment_params
      params.permit(:description)
    end

    # Build JSON response for attachment
    def attachment_json(attachment)
      {
        id: attachment.id,
        task_id: attachment.task_id,
        description: attachment.description,
        filename: attachment.file.filename.to_s,
        content_type: attachment.file.content_type,
        byte_size: attachment.file.byte_size,
        human_size: attachment.human_file_size,
        file_extension: attachment.file_extension,
        icon_class: attachment.icon_class,
        is_image: attachment.image?,
        is_markdown: attachment.markdown?,
        download_url: "/api/attachments/#{attachment.id}/download",
        view_url: "/api/attachments/#{attachment.id}/view",
        created_at: attachment.created_at
      }
    end
  end
end
