# ============================================================================
# Config Controller
# ============================================================================
#
# LEARNING NOTES:
#
# This controller serves Sparky's configuration files for viewing in the browser.
# It's a simple read-only interface to markdown files in the parent directory.
#
# KEY CONCEPTS:
# - Controllers handle HTTP requests and return responses
# - This controller doesn't use a model - it reads files directly
# - The files are markdown, rendered to HTML in the view
#
# COMPARISON TO NODE.JS:
# - Express: app.get('/config', (req, res) => { ... })
# - Rails:  def index ... end (with routes.rb mapping)
#
# ============================================================================

require 'redcarpet'

class ConfigController < ApplicationController
  # Config viewer is read-only and doesn't require authentication
  # (authenticate_user! is only defined in TasksController, not ApplicationController)
  
  # Base path for config files (parent of Rails app)
  CONFIG_PATH = Rails.root.join('..').freeze
  
  # List of allowed config files (security whitelist)
  ALLOWED_FILES = %w[
    SOUL.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md
    MEMORY.md IDENTITY.md CHANGELOG.md TEACHING_CODING.md FILE_LOCATIONS.md
  ].freeze
  
  # =======================================================================
  # GET /config
  # Shows the config file browser with sidebar
  # =======================================================================
  def index
    @files = config_file_list
    @current_file = params[:file] || 'SOUL.md'
    @file_content = read_config_file(@current_file)
    @file_metadata = file_metadata(@current_file)
  end
  
  # =======================================================================
  # GET /config/files
  # API endpoint returning list of available files (JSON)
  # =======================================================================
  def files
    render json: config_file_list
  end
  
  # =======================================================================
  # GET /config/:file
  # Shows a specific config file
  # =======================================================================
  def show
    filename = params[:file]
    
    unless ALLOWED_FILES.include?(filename)
      redirect_to config_path, alert: 'File not found' and return
    end
    
    @files = config_file_list
    @current_file = filename
    @file_content = read_config_file(filename)
    @file_metadata = file_metadata(filename)
    
    # Force HTML format (file param ends with .md but we render HTML)
    render :index, formats: [:html]
  end
  
  private
  
  # =======================================================================
  # Build list of config files with metadata
  # =======================================================================
  def config_file_list
    [
      { id: 'SOUL', name: 'SOUL.md', label: 'Soul', description: 'Who Sparky is' },
      { id: 'AGENTS', name: 'AGENTS.md', label: 'Agents', description: 'Workspace conventions' },
      { id: 'USER', name: 'USER.md', label: 'User', description: 'About MechDog' },
      { id: 'TOOLS', name: 'TOOLS.md', label: 'Tools', description: 'Local tool notes' },
      { id: 'HEARTBEAT', name: 'HEARTBEAT.md', label: 'Heartbeat', description: 'Periodic checks' },
      { id: 'MEMORY', name: 'MEMORY.md', label: 'Memory', description: 'Long-term memory' },
      { id: 'IDENTITY', name: 'IDENTITY.md', label: 'Identity', description: 'Sparky identity' },
      { id: 'CHANGELOG', name: 'CHANGELOG.md', label: 'Changelog', description: 'Recent changes' },
      { id: 'TEACHING_CODING', name: 'TEACHING_CODING.md', label: 'Teaching', description: 'Coding lessons' },
      { id: 'FILE_LOCATIONS', name: 'FILE_LOCATIONS.md', label: 'Files', description: 'File locations' }
    ]
  end
  
  # =======================================================================
  # Read a config file's contents
  # =======================================================================
  def read_config_file(filename)
    return nil unless ALLOWED_FILES.include?(filename)
    
    file_path = CONFIG_PATH.join(filename)
    
    if File.exist?(file_path)
      File.read(file_path)
    else
      "# File not found\n\nThe file `#{filename}` does not exist."
    end
  rescue => e
    "# Error reading file\n\n#{e.message}"
  end
  
  # =======================================================================
  # Get file metadata (size, modified time)
  # =======================================================================
  def file_metadata(filename)
    return nil unless ALLOWED_FILES.include?(filename)
    
    file_path = CONFIG_PATH.join(filename)
    
    if File.exist?(file_path)
      {
        size: File.size(file_path),
        modified: File.mtime(file_path)
      }
    else
      { size: 0, modified: nil }
    end
  rescue
    { size: 0, modified: nil }
  end
  
  # =======================================================================
  # Render markdown to HTML using Redcarpet
  # Made public for testing purposes
  # =======================================================================
  helper_method :render_markdown
  def render_markdown(text)
    return "" unless text
    
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )
    
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true
    )
    
    markdown.render(text).html_safe
  end
end
