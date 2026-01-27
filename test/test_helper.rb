# ============================================================================
# Test Helper
# ============================================================================
#
# LEARNING NOTES:
#
# This file is loaded before all tests. It sets up the test environment.
#
# KEY CONCEPTS:
# - ENV["RAILS_ENV"] = "test" - ensures we use test database
# - fixtures - sample data loaded automatically
# - parallelize - run tests in parallel for speed
#
# ============================================================================

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Disable if tests have shared state issues
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml
    # fixtures :all
    
    # Clean up database before each test
    setup do
      Task.destroy_all
    end

    # Add more helper methods to be used by all tests here...
  end
end

# ============================================================================
# Devise Integration Test Helper
# ============================================================================
#
# LEARNING NOTES:
#
# Devise provides test helpers for signing in/out during tests.
# For integration tests (controller tests that use get/post/etc.),
# we include Devise::Test::IntegrationHelpers.
#
# This lets us call `sign_in(user)` before making requests,
# simulating an authenticated session.
#
# Without this, any controller with `before_action :authenticate_user!`
# will redirect to the login page, and tests will fail with 302s.
#
# ============================================================================

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
