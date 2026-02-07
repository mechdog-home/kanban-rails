# ============================================================================
# Controller: QuickNotesController
# ============================================================================
#
# LEARNING NOTES:
#
# This controller handles all quick note-related HTTP requests.
# QuickNotes are simple scratchpad entries for quick ideas and thoughts.
#
# COMPARISON TO TASKS CONTROLLER:
# - Tasks have complex workflow (status, assignee, priority)
# - QuickNotes are simpler: just title and content
# - Both use standard RESTful patterns for consistency
#
# API ENDPOINTS:
# - GET    /quick_notes      -> index (list all notes)
# - GET    /quick_notes/:id  -> show (single note)
# - POST   /quick_notes      -> create (new note)
# - PATCH  /quick_notes/:id  -> update (modify note)
# - DELETE /quick_notes/:id  -> destroy (remove note)
#
# ============================================================================

class QuickNotesController < ApplicationController
  # Skip CSRF for API requests (JSON format)
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  
  # Require login for HTML views
  before_action :authenticate_user!, unless: -> { request.format.json? }
  
  # Find the note before show, edit, update, destroy
  before_action :set_quick_note, only: [:show, :edit, :update, :destroy]
  
  # ==========================================================================
  # GET /quick_notes
  # ==========================================================================
  #
  # List all quick notes, most recent first.
  # Supports both HTML and JSON formats.
  #
  def index
    @quick_notes = QuickNote.recent
    
    respond_to do |format|
      format.html  # Renders app/views/quick_notes/index.html.slim
      format.json { render json: @quick_notes }
    end
  end

  # ==========================================================================
  # GET /quick_notes/:id
  # ==========================================================================
  #
  # Show a single quick note.
  #
  def show
    respond_to do |format|
      format.html  # Renders app/views/quick_notes/show.html.slim
      format.json { render json: @quick_note }
    end
  end

  # ==========================================================================
  # GET /quick_notes/new
  # ==========================================================================
  #
  # Show form for creating a new quick note (HTML only).
  #
  def new
    @quick_note = QuickNote.new
  end

  # ==========================================================================
  # GET /quick_notes/:id/edit
  # ==========================================================================
  #
  # Show form for editing an existing quick note (HTML only).
  #
  def edit
  end

  # ==========================================================================
  # POST /quick_notes
  # ==========================================================================
  #
  # Create a new quick note.
  #
  # Request body (JSON):
  # {
  #   "title": "Note title",
  #   "content": "Note content"
  # }
  #
  def create
    @quick_note = QuickNote.new(quick_note_params)
    
    # Associate with current user if logged in
    @quick_note.user = current_user if current_user
    
    respond_to do |format|
      if @quick_note.save
        format.html { redirect_to quick_notes_path, notice: 'Quick note was successfully created.' }
        format.json { render json: @quick_note, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @quick_note.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # ==========================================================================
  # PATCH/PUT /quick_notes/:id
  # ==========================================================================
  #
  # Update an existing quick note.
  #
  def update
    respond_to do |format|
      if @quick_note.update(quick_note_params)
        format.html { redirect_to quick_notes_path, notice: 'Quick note was successfully updated.' }
        format.json { render json: @quick_note }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @quick_note.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # ==========================================================================
  # DELETE /quick_notes/:id
  # ==========================================================================
  #
  # Delete a quick note.
  #
  def destroy
    @quick_note.destroy
    
    respond_to do |format|
      format.html { redirect_to quick_notes_path, notice: 'Quick note was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================
  
  private

  # Find note by ID from URL parameter
  def set_quick_note
    @quick_note = QuickNote.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to quick_notes_path, alert: 'Quick note not found.' }
      format.json { render json: { error: 'Quick note not found' }, status: :not_found }
    end
  end

  # Strong parameters - only allow these attributes
  def quick_note_params
    params.require(:quick_note).permit(:title, :content)
  rescue ActionController::ParameterMissing
    # Allow params without :quick_note wrapper for API convenience
    params.permit(:title, :content)
  end
end
