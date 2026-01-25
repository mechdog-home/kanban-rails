# ============================================================================
# Helper: TasksHelper
# ============================================================================
#
# LEARNING NOTES:
#
# Helpers are modules that provide utility methods for views.
# They keep view logic out of templates, making them cleaner.
#
# KEY CONCEPTS:
# - Helpers are automatically available in views
# - Use for formatting, conditional styling, etc.
# - Keep complex logic in models, simple view logic in helpers
#
# ============================================================================

module TasksHelper
  # Map priority to Bootstrap color class
  # Usage: bg-#{priority_color(task.priority)}
  def priority_color(priority)
    case priority
    when 'urgent' then 'danger'
    when 'high' then 'warning'
    when 'medium' then 'info'
    when 'low' then 'success'
    else 'secondary'
    end
  end
  
  # Map status to Bootstrap color class
  def status_color(status)
    case status
    when 'done' then 'success'
    when 'in_progress' then 'primary'
    when 'review' then 'info'
    when 'backlog' then 'secondary'
    else 'secondary'
    end
  end
end
