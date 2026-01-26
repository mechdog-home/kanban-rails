# ============================================================================
# Rake Tasks: User Management
# ============================================================================
#
# LEARNING NOTES:
#
# Rake tasks are command-line scripts for maintenance operations.
# These help with user management from the terminal.
#
# USAGE:
#   rails users:create_super_admin    # Interactive super admin creation
#   rails users:set_role[email,role]  # Change a user's role
#   rails users:list                  # List all users
#
# ============================================================================

namespace :users do
  desc "Create a super admin user (interactive)"
  task create_super_admin: :environment do
    puts "\n=== Create Super Admin User ===\n\n"
    
    print "Email: "
    email = STDIN.gets.chomp
    
    print "Name: "
    name = STDIN.gets.chomp
    
    print "Password: "
    # Try to hide password input
    begin
      system("stty -echo")
      password = STDIN.gets.chomp
    ensure
      system("stty echo")
    end
    puts ""
    
    print "Confirm Password: "
    begin
      system("stty -echo")
      password_confirmation = STDIN.gets.chomp
    ensure
      system("stty echo")
    end
    puts ""
    
    user = User.new(
      email: email,
      name: name,
      password: password,
      password_confirmation: password_confirmation,
      role: 'super_admin'
    )
    
    if user.save
      puts "\n✅ Super admin '#{name}' created successfully!"
      puts "   Email: #{email}"
      puts "   Role: super_admin"
    else
      puts "\n❌ Failed to create user:"
      user.errors.full_messages.each do |msg|
        puts "   - #{msg}"
      end
    end
  end
  
  desc "Set a user's role (usage: rails users:set_role[email,role])"
  task :set_role, [:email, :role] => :environment do |t, args|
    email = args[:email]
    role = args[:role]
    
    if email.blank? || role.blank?
      puts "Usage: rails users:set_role[email,role]"
      puts "Roles: #{User::ROLES.join(', ')}"
      exit 1
    end
    
    user = User.find_by(email: email)
    
    if user.nil?
      puts "❌ User not found: #{email}"
      exit 1
    end
    
    unless User::ROLES.include?(role)
      puts "❌ Invalid role: #{role}"
      puts "Valid roles: #{User::ROLES.join(', ')}"
      exit 1
    end
    
    user.update!(role: role)
    puts "✅ #{user.name} (#{email}) is now a #{role.titleize.gsub('_', ' ')}"
  end
  
  desc "List all users"
  task list: :environment do
    puts "\n=== All Users ===\n\n"
    puts sprintf("%-30s %-30s %-15s", "Name", "Email", "Role")
    puts "-" * 75
    
    User.order(:name).each do |user|
      puts sprintf("%-30s %-30s %-15s", user.name, user.email, user.role)
    end
    
    puts "\nTotal: #{User.count} users"
  end
  
  desc "Create a user from command line (usage: rails users:create[email,name,password,role])"
  task :create, [:email, :name, :password, :role] => :environment do |t, args|
    email = args[:email]
    name = args[:name]
    password = args[:password]
    role = args[:role] || 'user'
    
    if email.blank? || name.blank? || password.blank?
      puts "Usage: rails users:create[email,name,password,role]"
      puts "Role is optional, defaults to 'user'"
      exit 1
    end
    
    user = User.new(
      email: email,
      name: name,
      password: password,
      password_confirmation: password,
      role: role
    )
    
    if user.save
      puts "✅ User '#{name}' created successfully!"
      puts "   Email: #{email}"
      puts "   Role: #{role}"
    else
      puts "❌ Failed to create user:"
      user.errors.full_messages.each do |msg|
        puts "   - #{msg}"
      end
    end
  end
end
