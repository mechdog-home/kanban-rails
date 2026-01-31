# ============================================================================
# Migration: Set Default User Passwords
# ============================================================================
#
# LEARNING NOTES:
#
# This migration ensures the default users (mechdog and sparky) have
# their passwords set to 'pass6767'. It runs after the users are created
# via seeds.rb, updating their passwords if they exist.
#
# Using `up` method (not `change`) because this is data migration,
# not schema change. `down` is empty since we don't want to revert
# passwords to unknown values.
#
# `reset_password` is a Devise method that properly updates the encrypted
# password without needing password_confirmation.
#
# ============================================================================

class SetDefaultUserPasswords < ActiveRecord::Migration[8.1]
  def up
    # Update mechdog's password if user exists
    mechdog = User.find_by(username: "mechdog")
    if mechdog
      mechdog.password = "pass6767"
      mechdog.password_confirmation = "pass6767"
      mechdog.save(validate: false)  # Skip validation to ensure save succeeds
      puts "  ✓ Updated password for mechdog"
    end

    # Update sparky's password if user exists
    sparky = User.find_by(username: "sparky")
    if sparky
      sparky.password = "pass6767"
      sparky.password_confirmation = "pass6767"
      sparky.save(validate: false)  # Skip validation to ensure save succeeds
      puts "  ✓ Updated password for sparky"
    end
  end

  def down
    # No-op: we don't revert passwords to avoid locking users out
    # If needed, manual password reset via console is safer
  end
end
