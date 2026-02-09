# ============================================================================
# Controller: TaskAttachmentsController
# ============================================================================
#
# Handles file uploads and downloads for task attachments via HTML interface.
# This is for the web UI, separate from the API controller.
#
# ROUTES:
# - GET    /tasks/:task_id/attachments/new    -> Upload form
# - POST   /tasks/:task_id/attachments        -> Create attachment
# - DELETE /tasks/:task_id/attachments/:id    -> Delete attachment
# - GET    /attachments/:id/download          -> Download file
#
# ============================================================================

class TaskAttachmentsController < ApplicationController
  before_action :set_task
  before_action :set_attachment, only: [:destroy, :download]

  # ========================================================================
  # GET /tasks/:task_id/attachments/new
  # ========================================================================
  def new
    @attachment = @task.attachments.new
  end

  # ========================================================================
  # POST /tasks/:task_id/attachments
  # ========================================================================
  def create
    @attachment = @task.attachments.new(attachment_params)
    
    if params[:attachment].present? && params[:attachment][:file].present?
      @attachment.file.attach(params[:attachment][:file])
    end
    
    if @attachment.save
      redirect_to task_path(@task), notice: 'File uploaded successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ========================================================================
  # DELETE /tasks/:task_id/attachments/:id
  # ========================================================================
  def destroy
    @attachment.destroy
    redirect_to task_path(@task), notice: 'Attachment deleted.'
  end

  # ========================================================================
  # GET /tasks/:task_id/attachments/:id/download
  # ========================================================================
  def download
    redirect_to @attachment.file.url(disposition: 'attachment')
  rescue => e
    redirect_to task_path(@task), alert: "Download failed: #{e.message}"
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_attachment
    @attachment = @task.attachments.find(params[:id])
  end

  def attachment_params
    params.require(:attachment).permit(:description)
  end
end
