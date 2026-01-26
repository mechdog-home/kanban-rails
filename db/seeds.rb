# ============================================================================
# Seeds: Sample Data for Development
# ============================================================================
#
# LEARNING NOTES:
#
# Seeds populate the database with initial data for development/testing.
# Run with: rails db:seed
#
# KEY CONCEPTS:
# - Use find_or_create_by to avoid duplicates on re-runs
# - Set strong passwords in development (they're not in version control)
# - Associate tasks with users for ownership tracking
#
# ============================================================================

puts "Seeding users..."

# Create MechDog user (main human user)
mechdog = User.find_or_create_by!(email: 'mark@kenneywww.com') do |user|
  user.name = 'MechDog'
  user.password = 'password123'  # Change in production!
  user.password_confirmation = 'password123'
end
puts "  Created/found user: #{mechdog.email}"

# Create Sparky user (AI assistant)
sparky = User.find_or_create_by!(email: 'sparky@clawd.bot') do |user|
  user.name = 'Sparky'
  user.password = 'password123'  # Change in production!
  user.password_confirmation = 'password123'
end
puts "  Created/found user: #{sparky.email}"

puts "Created #{User.count} users!"
puts ""
puts "Seeding tasks..."

# Clear existing tasks for clean seed
Task.destroy_all

# MechDog's tasks
Task.create!(
  title: "Review Rails Kanban port",
  description: "Check that all features work correctly compared to Node version",
  assignee: "mechdog",
  status: "backlog",
  priority: "high",
  user: mechdog
)

Task.create!(
  title: "Test shot timer on device",
  description: "Load APK on Android phone and test microphone detection",
  assignee: "mechdog",
  status: "backlog",
  priority: "medium",
  user: mechdog
)

Task.create!(
  title: "BBQData feature request",
  description: "Add new competition category for regional events",
  assignee: "mechdog",
  status: "in_progress",
  priority: "medium",
  user: mechdog
)

# Sparky's tasks
Task.create!(
  title: "Flutter Shot Timer",
  description: "Build shot timer app with microphone detection and adjustable sensitivity",
  assignee: "sparky",
  status: "in_progress",
  priority: "high",
  user: sparky
)

Task.create!(
  title: "Rails Kanban Board",
  description: "Port Node.js kanban to Rails with SLIM templates and Bootstrap",
  assignee: "sparky",
  status: "in_progress",
  priority: "high",
  user: sparky
)

Task.create!(
  title: "Flutter Example App",
  description: "Create a basic Flutter app to demonstrate patterns",
  assignee: "sparky",
  status: "backlog",
  priority: "medium",
  user: sparky
)

Task.create!(
  title: "PractiScore integration",
  description: "Set up automated match alerts for USPSA/PCSL/GPA",
  assignee: "sparky",
  status: "backlog",
  priority: "low",
  user: sparky
)

puts "Created #{Task.count} tasks!"
puts ""
puts "Seed complete! 🌱"
