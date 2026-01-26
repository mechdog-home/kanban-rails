# ============================================================================
# Seeds: Sample Data for Development
# ============================================================================
#
# LEARNING NOTES:
#
# Seeds populate the database with initial data for development/testing.
# Run with: rails db:seed
#
# NOTE: This does NOT create a super_admin. Use the rake task:
#   rails users:create_super_admin
#
# ============================================================================

puts "Seeding tasks..."

# Clear existing tasks for clean seed
Task.destroy_all

# Sample tasks (no user association - you'll assign after creating users)
Task.create!(
  title: "Review Rails Kanban port",
  description: "Check that all features work correctly compared to Node version",
  assignee: "mechdog",
  status: "backlog",
  priority: "high"
)

Task.create!(
  title: "Test shot timer on device",
  description: "Load APK on Android phone and test microphone detection",
  assignee: "mechdog",
  status: "backlog",
  priority: "medium"
)

Task.create!(
  title: "BBQData feature request",
  description: "Add new competition category for regional events",
  assignee: "mechdog",
  status: "in_progress",
  priority: "medium"
)

Task.create!(
  title: "Flutter Shot Timer",
  description: "Build shot timer app with microphone detection and adjustable sensitivity",
  assignee: "sparky",
  status: "in_progress",
  priority: "high"
)

Task.create!(
  title: "Rails Kanban Board",
  description: "Port Node.js kanban to Rails with SLIM templates and Bootstrap",
  assignee: "sparky",
  status: "in_progress",
  priority: "high"
)

puts "Created #{Task.count} tasks!"
puts ""
puts "To create a super admin user, run:"
puts "  rails users:create_super_admin"
puts ""
puts "Then add other users via the web UI or:"
puts "  rails users:create[email,name,password,role]"
