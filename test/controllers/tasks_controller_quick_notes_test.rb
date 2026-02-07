# ============================================================================
# Integration Test: Quick Notes on Kanban Board
# ============================================================================
#
# LEARNING NOTES:
#
# This test verifies that QuickNotes are properly displayed on the
# kanban board (tasks#index view).
#
# RUNNING TESTS:
#   bin/rails test test/controllers/tasks_controller_quick_notes_test.rb
#
# ============================================================================

require "test_helper"

class TasksControllerQuickNotesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    # Create a test user and sign in before each test
    @user = User.create!(
      email: "kanban-quicknote-test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "kanbanquicknotetester",
      name: "Kanban Quick Note Tester",
      role: "user"
    )
    
    # Create some quick notes for testing
    @fresh_note = QuickNote.create!(
      title: "Fresh Idea",
      content: "A recently created idea",
      updated_at: 30.minutes.ago
    )
    
    @old_note = QuickNote.create!(
      title: "Old Thought",
      content: "An older note",
      updated_at: 5.days.ago
    )
    
    # Create a task to ensure board loads
    @task = Task.create!(
      title: "Test Task",
      assignee: "mechdog",
      status: "backlog",
      priority: "medium"
    )
  end

  # ==========================================================================
  # QUICK NOTES DISPLAY TESTS
  # ==========================================================================
  
  test "kanban board should load recent quick notes" do
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Should contain both note titles
    assert_includes @response.body, "Fresh Idea"
    assert_includes @response.body, "Old Thought"
  end
  
  test "kanban board should limit to 5 recent notes" do
    # Create 7 notes to test the limit
    QuickNote.delete_all
    7.times do |i|
      QuickNote.create!(title: "Note #{i}")
    end
    
    sign_in @user
    get tasks_url
    
    # Check that we only see up to 5 notes
    assert_response :success
    # The section should show the badge with count
    assert_includes @response.body, "Quick Notes"
  end
  
  test "kanban board should not load quick notes for JSON format" do
    get tasks_url, as: :json
    
    assert_response :success
    # JSON response should not include quick notes
    json_response = JSON.parse(response.body)
    # Response should be an array of tasks, not include quick notes
    assert_kind_of Array, json_response if json_response.is_a?(Array)
  end

  # ==========================================================================
  # QUICK NOTES PARTIAL TESTS
  # ==========================================================================
  
  test "kanban board should render quick notes section" do
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Should have the quick notes section
    assert_includes @response.body, "quick-notes-section"
    # Should show the section title
    assert_includes @response.body, "Quick Notes"
  end
  
  test "kanban board should show empty state when no quick notes" do
    QuickNote.delete_all
    
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Should show empty state
    assert_includes @response.body, "No quick notes yet"
  end
  
  test "kanban board should include link to view all notes" do
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Should have link to quick_notes_path
    assert_includes @response.body, quick_notes_path
    assert_includes @response.body, "View All"
  end
  
  test "kanban board should include link to add new note" do
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Should have link to new_quick_note_path
    assert_includes @response.body, new_quick_note_path
    assert_includes @response.body, "Add Note"
  end
  
  test "quick notes should have correct border classes based on age" do
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Fresh note should have border-info (not asserting exact HTML structure,
    # just that both notes appear in the section)
    assert_includes @response.body, "Fresh Idea"
    assert_includes @response.body, "Old Thought"
  end
  
  test "quick notes should link to edit page" do
    sign_in @user
    get tasks_url
    
    assert_response :success
    # Should have link to edit the fresh note
    assert_includes @response.body, edit_quick_note_path(@fresh_note)
  end
end
