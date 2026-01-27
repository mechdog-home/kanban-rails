# ============================================================================
# Seeds: Sample Data for Development
# ============================================================================
#
# LEARNING NOTES:
#
# Seeds populate the database with initial data for development/testing.
# Run with: rails db:seed
#
# This creates two default users:
# - mechdog (super_admin) — MechDog's account
# - sparky (admin) — Sparky's account
#
# And sample tasks to work with.
#
# `find_or_create_by` ensures running seeds twice won't create duplicates.
#
# ============================================================================

puts "Seeding users..."

# Create default users (find_or_create prevents duplicates on re-seed)
mechdog = User.find_or_create_by!(username: "mechdog") do |u|
  u.name = "MechDog"
  u.email = "mechdog@kanban.local"
  u.password = "changeme123"
  u.password_confirmation = "changeme123"
  u.role = "super_admin"
end
puts "  ✓ mechdog (super_admin) — password: changeme123"

sparky = User.find_or_create_by!(username: "sparky") do |u|
  u.name = "Sparky"
  u.email = "sparky@kanban.local"
  u.password = "changeme123"
  u.password_confirmation = "changeme123"
  u.role = "admin"
end
puts "  ✓ sparky (admin) — password: changeme123"

puts ""
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
