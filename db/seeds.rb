# ============================================================================
# Seeds: Sample Data for Development
# ============================================================================
#
# LEARNING NOTES:
#
# Seeds populate the database with initial data for development/testing.
# Run with: rails db:seed
#
# ============================================================================

puts "Seeding tasks..."

# Clear existing tasks
Task.destroy_all

# MechDog's tasks
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

# Sparky's tasks
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

Task.create!(
  title: "Flutter Example App",
  description: "Create a basic Flutter app to demonstrate patterns",
  assignee: "sparky",
  status: "backlog",
  priority: "medium"
)

Task.create!(
  title: "PractiScore integration",
  description: "Set up automated match alerts for USPSA/PCSL/GPA",
  assignee: "sparky",
  status: "backlog",
  priority: "low"
)

puts "Created #{Task.count} tasks!"
