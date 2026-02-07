# ============================================================================
# Model: QuickNote
# ============================================================================
#
# LEARNING NOTES:
#
# This model represents quick notes/ideas that users can jot down
# without creating full tasks. It's a lightweight way to capture
# thoughts and reminders.
#
# Unlike Tasks, QuickNotes are simpler:
# - No workflow status (just created/updated timestamps)
# - No assignee or priority
# - Just title and content for quick capture
#
# COMPARISON TO TASK MODEL:
# - Task: Full workflow, assignees, priorities, complex
# - QuickNote: Simple scratchpad, no workflow, quick to create
#
# ============================================================================

class QuickNote < ApplicationRecord
  # ==========================================================================
  # ASSOCIATIONS
  # ==========================================================================
  #
  # LEARNING NOTE: QuickNotes can optionally belong to a user
  # This allows filtering by user later if needed
  
  belongs_to :user, optional: true

  # ==========================================================================
  # VALIDATIONS
  # ==========================================================================
  #
  # LEARNING NOTE: Keep validations minimal for quick capture
  # Title is required but content can be blank for ultra-quick notes
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, length: { maximum: 10000 }

  # ==========================================================================
  # SCOPES
  # ==========================================================================
  #
  # LEARNING NOTE: Scopes provide reusable query fragments
  # These help us fetch notes for display on the kanban board
  
  # Order by most recently updated first (default order)
  scope :recent, -> { order(updated_at: :desc) }
  
  # Order by most recently created
  scope :newest, -> { order(created_at: :desc) }
  
  # Get notes created/updated in the last 7 days
  scope :this_week, -> { where('updated_at >= ?', 7.days.ago) }
  
  # Get notes updated in the last 24 hours
  scope :today, -> { where('updated_at >= ?', 1.day.ago) }
  
  # Search notes by title or content
  scope :search, ->(query) {
    where('title LIKE ? OR content LIKE ?', "%#{query}%", "%#{query}%")
  }

  # ==========================================================================
  # CLASS METHODS
  # ==========================================================================
  
  # Get the most recent notes for display on kanban board
  # Default to 5 most recent notes
  def self.recent_for_board(limit = 5)
    recent.limit(limit)
  end
  
  # Get note count for dashboard/quick stats
  def self.total_count
    count
  end
  
  # Get count of notes created today
  def self.created_today_count
    where('created_at >= ?', Date.today.beginning_of_day).count
  end

  # ==========================================================================
  # INSTANCE METHODS
  # ==========================================================================
  
  # Check if note was updated since creation
  def edited?
    updated_at > created_at
  end
  
  # Human-readable time since last update
  # Uses Rails' time_ago_in_words helper
  def time_since_update
    return "Just now" if updated_at > 1.minute.ago
    ApplicationController.helpers.time_ago_in_words(updated_at) + " ago"
  end
  
  # Get a truncated preview of content for card display
  def preview(length = 100)
    return "" if content.blank?
    content.length > length ? content[0...length] + "..." : content
  end
  
  # Get a color based on age (for visual grouping)
  # Newer notes = brighter, older = more muted
  def age_category
    days_old = (Time.current - updated_at) / 1.day
    
    if days_old < 1
      :fresh      # Less than 24 hours
    elsif days_old < 3
      :recent     # 1-3 days
    elsif days_old < 7
      :week_old   # 3-7 days
    else
      :old        # Older than a week
    end
  end
  
  # CSS class based on age for styling
  def age_css_class
    case age_category
    when :fresh then "border-info"
    when :recent then "border-success"
    when :week_old then "border-warning"
    else "border-secondary"
    end
  end
end
