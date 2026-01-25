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
