#!/usr/bin/env ruby
# encoding: utf-8
# Migration script: Node.js kanban tasks → Rails kanban tasks
# Compares titles to avoid duplicates, migrates non-matching tasks

require 'json'
require 'net/http'
require 'uri'
require 'set'

# Read Node.js tasks from exported JSON with UTF-8 encoding
node_json = File.read('/tmp/node_tasks.json', encoding: 'UTF-8')
node_tasks = JSON.parse(node_json)

# Fetch Rails tasks
rails_uri = URI('http://localhost:6767/api/tasks')
rails_response = Net::HTTP.get(rails_uri)
rails_tasks = JSON.parse(rails_response)

# Build set of existing Rails task titles (lowercase for comparison)
rails_titles = rails_tasks.map { |t| t['title'].downcase.strip }.to_set

puts "=" * 60
puts "KANBAN MIGRATION REPORT"
puts "=" * 60
puts "\nNode.js tasks found: #{node_tasks.length}"
puts "Rails tasks found: #{rails_tasks.length}"

# Find tasks that need migration
# (titles that don't exist in Rails, excluding the migration task itself)
tasks_to_migrate = node_tasks.reject do |task|
  title = task['title'].downcase.strip
  rails_titles.include?(title) || title.include?('migrate any node.js')
end

puts "\nTasks to migrate: #{tasks_to_migrate.length}"
puts "-" * 60

tasks_to_migrate.each do |task|
  puts "\n[#{task['id']}] #{task['title']}"
  puts "    Assignee: #{task['assignee']} | Status: #{task['status']} | Priority: #{task['priority']}"
end

# Migrate tasks
migrated_count = 0
errors = []

tasks_to_migrate.each do |task|
  # Map priority values if needed (Node uses 'low', 'medium', 'high' - Rails may differ)
  priority = case task['priority']
             when 'high' then 'high'
             when 'medium' then 'medium'
             when 'low' then 'low'
             else 'medium'
             end

  # Prepare payload
  payload = {
    task: {
      title: task['title'],
      description: task['description'] || '',
      assignee: task['assignee'],
      status: task['status'],
      priority: priority
    }
  }

  uri = URI('http://localhost:6767/api/tasks')
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
  request.body = payload.to_json

  begin
    response = http.request(request)
    if response.code == '201' || response.code == '200'
      migrated_count += 1
      puts "✅ Migrated: #{task['title']}"
    else
      errors << "[#{task['id']}] #{task['title']}: HTTP #{response.code} - #{response.body}"
      puts "❌ Failed: #{task['title']} (HTTP #{response.code})"
    end
  rescue => e
    errors << "[#{task['id']}] #{task['title']}: #{e.message}"
    puts "❌ Error: #{task['title']} - #{e.message}"
  end
end

puts "\n" + "=" * 60
puts "MIGRATION COMPLETE"
puts "=" * 60
puts "Migrated: #{migrated_count}/#{tasks_to_migrate.length} tasks"

if errors.any?
  puts "\nErrors encountered:"
  errors.each { |e| puts "  - #{e}" }
end

# Mark migrated tasks in Node.js DB by adding a migrated flag
if migrated_count > 0
  puts "\n⚠️  Note: Node.js DB does not have a 'migrated' column."
  puts "   To prevent future duplicate migrations, you should either:"
  puts "   1. Add a 'migrated_to_rails' boolean column to the tasks table"
  puts "   2. Or delete the migrated tasks from Node.js"
  puts "   3. Or shut down the Node.js kanban board"
end
