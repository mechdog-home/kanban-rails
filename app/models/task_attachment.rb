# ============================================================================
# Model: TaskAttachment
# ============================================================================
#
# LEARNING NOTES:
#
# This model represents a file attachment for a Task.
# Uses ActiveStorage to handle file uploads and storage.
#
# KEY CONCEPTS:
# - ActiveStorage handles file uploads, storage, and retrieval
# - has_one_attached :file creates the association
# - Files are stored in storage/ directory (configured in storage.yml)
#
# COMPARISON TO EXPRESS/MONGOOSE:
# - Express: You'd use multer for uploads, store paths in DB
# - Rails: ActiveStorage handles everything - storage, retrieval, URLs
#
# SECURITY NOTES:
# - Validate file types to prevent malicious uploads
# - Limit file size to prevent storage abuse
# - Consider virus scanning for production
#
# ============================================================================

class TaskAttachment < ApplicationRecord
  # ==========================================================================
  # ASSOCIATIONS
  # ==========================================================================
  
  # Each attachment belongs to a task
  belongs_to :task
  
  # ActiveStorage attachment
  # This creates the association to the uploaded file
  has_one_attached :file
  
  # ==========================================================================
  # VALIDATIONS
  # ==========================================================================
  
  # Description is optional but recommended
  validates :description, length: { maximum: 500 }
  
  # Validate file is attached
  validate :file_must_be_attached
  
  # Validate file type (whitelist approach for security)
  validate :acceptable_file_type
  
  # Validate file size (max 10MB)
  validate :acceptable_file_size
  
  # ==========================================================================
  # SCOPES
  # ==========================================================================
  
  # Order by most recent first
  scope :recent, -> { order(created_at: :desc) }
  
  # Get image attachments only
  scope :images, -> { where("content_type LIKE ?", "image/%") }
  
  # Get document attachments
  scope :documents, -> { where("content_type IN (?)", %w[
    text/plain text/markdown application/pdf 
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/csv application/json
  ]) }

  # ==========================================================================
  # CALLBACKS
  # ==========================================================================
  
  # Store file metadata after attachment
  after_commit :extract_metadata, on: :create
  
  # ==========================================================================
  # INSTANCE METHODS
  # ==========================================================================
  
  # Check if attachment is an image
  def image?
    file.content_type&.start_with?('image/')
  end
  
  # Check if attachment is a markdown file
  def markdown?
    file.filename.to_s.end_with?('.md', '.markdown') || 
      file.content_type == 'text/markdown'
  end
  
  # Check if attachment is a PDF
  def pdf?
    file.content_type == 'application/pdf'
  end
  
  # Get human-readable file size
  def human_file_size
    return "0 B" unless file.byte_size.present?
    
    byte_size = file.byte_size
    
    if byte_size < 1024
      "#{byte_size} B"
    elsif byte_size < 1024 * 1024
      "#{(byte_size / 1024.0).round(1)} KB"
    else
      "#{(byte_size / (1024.0 * 1024)).round(1)} MB"
    end
  end
  
  # Get file extension
  def file_extension
    file.filename.to_s.split('.').last&.downcase
  end
  
  # Get icon class based on file type (for UI)
  def icon_class
    case file_extension
    when 'md', 'markdown'
      'bi-filetype-md'
    when 'pdf'
      'bi-filetype-pdf'
    when 'txt'
      'bi-filetype-txt'
    when 'jpg', 'jpeg', 'png', 'gif', 'webp'
      'bi-file-image'
    when 'doc', 'docx'
      'bi-filetype-doc'
    when 'csv'
      'bi-filetype-csv'
    when 'json'
      'bi-filetype-json'
    else
      'bi-file-earmark'
    end
  end
  
  # Get display name (description or filename)
  def display_name
    description.present? ? description : file.filename.to_s
  end
  
  # Download URL for API
  def download_url
    Rails.application.routes.url_helpers.rails_blob_path(file, disposition: 'attachment')
  end
  
  # View URL for API (inline for images)
  def view_url
    Rails.application.routes.url_helpers.rails_blob_path(file, disposition: 'inline')
  end
  
  # As JSON for API responses
  def as_json(options = {})
    super(options.merge(
      methods: [:display_name, :human_file_size, :file_extension, :icon_class, :image?, :markdown?],
      include: {
        file: {
          only: [:filename, :byte_size, :content_type],
          methods: [:url]
        }
      }
    )).merge(
      download_url: download_url,
      view_url: view_url
    )
  end

  private
  
  # Validation: File must be attached
  def file_must_be_attached
    unless file.attached?
      errors.add(:file, "must be attached")
    end
  end
  
  # Validation: Check file type against whitelist
  def acceptable_file_type
    return unless file.attached?
    
    allowed_types = %w[
      image/jpeg image/png image/gif image/webp
      text/plain text/markdown
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      text/csv
      application/json
    ]
    
    # Also allow by extension for files without proper MIME type
    allowed_extensions = %w[.md .markdown .txt .pdf .jpg .jpeg .png .gif .webp .doc .docx .csv .json]
    
    unless allowed_types.include?(file.content_type) || 
           allowed_extensions.any? { |ext| file.filename.to_s.downcase.end_with?(ext) }
      errors.add(:file, "must be an image, PDF, document, or text file")
    end
  end
  
  # Validation: Check file size
  def acceptable_file_size
    return unless file.attached?
    
    if file.byte_size > 10.megabytes
      errors.add(:file, "is too big (max 10MB)")
    end
  end
  
  # Callback: Extract and store metadata
  def extract_metadata
    return unless file.attached?
    
    # Content type is automatically set by ActiveStorage
    # We could extract more metadata here (image dimensions, etc.)
    update_column(:content_type, file.content_type) if content_type.blank?
  end
end
