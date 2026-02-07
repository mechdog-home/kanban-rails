# ============================================================================
# Controller Tests: QuickNotesController
# ============================================================================
#
# LEARNING NOTES:
#
# Controller tests verify that HTTP requests are handled correctly.
# We test all CRUD actions and both HTML and JSON formats.
#
# RUNNING TESTS:
#   bin/rails test test/controllers/quick_notes_controller_test.rb
#
# ============================================================================

require "test_helper"

class QuickNotesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # ==========================================================================
  # SETUP
  # ==========================================================================
  
  def setup
    # Create a test user and sign in before each test
    @user = User.create!(
      email: "quicknote-test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "quicknotetester",
      name: "Quick Note Tester",
      role: "user"
    )
    
    @quick_note = QuickNote.create!(
      title: "Test Note",
      content: "Test content for the note"
    )
  end

  # ==========================================================================
  # AUTHENTICATION TESTS
  # ==========================================================================
  
  test "should redirect to login when accessing index without authentication" do
    get quick_notes_url
    assert_redirected_to new_user_session_path
  end
  
  test "should allow index access when authenticated" do
    sign_in @user
    get quick_notes_url
    assert_response :success
  end
  
  test "should allow JSON access without authentication" do
    get quick_notes_url, as: :json
    assert_response :success
  end

  # ==========================================================================
  # INDEX ACTION TESTS
  # ==========================================================================
  
  test "index should load successfully" do
    sign_in @user
    get quick_notes_url
    assert_response :success
    # Should contain the note title in the response
    assert_includes @response.body, "Test Note"
  end
  
  test "index should return JSON array" do
    get quick_notes_url, as: :json
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
    assert_equal 1, json_response.length
    assert_equal "Test Note", json_response[0]["title"]
  end

  # ==========================================================================
  # SHOW ACTION TESTS
  # ==========================================================================
  
  test "show should return JSON object" do
    get quick_note_url(@quick_note), as: :json
    json_response = JSON.parse(response.body)
    assert_equal "Test Note", json_response["title"]
    assert_equal "Test content for the note", json_response["content"]
  end
  
  test "show should handle not found" do
    sign_in @user
    get quick_note_url(id: 999999)
    assert_redirected_to quick_notes_path
    assert_equal "Quick note not found.", flash[:alert]
  end

  # ==========================================================================
  # NEW ACTION TESTS
  # ==========================================================================
  
  test "new should render form" do
    sign_in @user
    get new_quick_note_url
    assert_response :success
    # Should contain form elements
    assert_includes @response.body, "Title"
    assert_includes @response.body, "Content"
  end

  # ==========================================================================
  # CREATE ACTION TESTS
  # ==========================================================================
  
  test "create should create new note with valid params" do
    sign_in @user
    
    assert_difference("QuickNote.count", 1) do
      post quick_notes_url, params: {
        quick_note: { title: "New Note", content: "New content" }
      }
    end
    
    assert_redirected_to quick_notes_path
    assert_equal "Quick note was successfully created.", flash[:notice]
  end
  
  test "create should associate note with current user" do
    sign_in @user
    
    post quick_notes_url, params: {
      quick_note: { title: "User Note", content: "Content" }
    }
    
    note = QuickNote.order(:created_at).last
    assert_equal @user, note.user
  end
  
  test "create should render new with invalid params" do
    sign_in @user
    
    assert_no_difference("QuickNote.count") do
      post quick_notes_url, params: {
        quick_note: { title: "", content: "Content" }
      }
    end
    
    assert_response :unprocessable_entity
  end
  
  test "create should return JSON with created status on success" do
    post quick_notes_url, params: {
      quick_note: { title: "API Note", content: "API content" }
    }, as: :json
    
    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "API Note", json_response["title"]
  end
  
  test "create should return JSON errors on failure" do
    post quick_notes_url, params: {
      quick_note: { title: "", content: "Content" }
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end
  
  test "create should accept params without quick_note wrapper" do
    post quick_notes_url, params: {
      title: "Unwrapped Note", content: "Unwrapped content"
    }, as: :json
    
    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "Unwrapped Note", json_response["title"]
  end

  # ==========================================================================
  # EDIT ACTION TESTS
  # ==========================================================================
  
  test "edit should render form for existing note" do
    sign_in @user
    get edit_quick_note_url(@quick_note)
    assert_response :success
    # Should contain the note title in the form
    assert_includes @response.body, "Test Note"
  end

  # ==========================================================================
  # UPDATE ACTION TESTS
  # ==========================================================================
  
  test "update should modify existing note" do
    sign_in @user
    
    patch quick_note_url(@quick_note), params: {
      quick_note: { title: "Updated Title", content: "Updated content" }
    }
    
    assert_redirected_to quick_notes_path
    assert_equal "Quick note was successfully updated.", flash[:notice]
    
    @quick_note.reload
    assert_equal "Updated Title", @quick_note.title
    assert_equal "Updated content", @quick_note.content
  end
  
  test "update should render edit with invalid params" do
    sign_in @user
    
    patch quick_note_url(@quick_note), params: {
      quick_note: { title: "", content: "Updated content" }
    }
    
    assert_response :unprocessable_entity
  end
  
  test "update should return JSON on success" do
    patch quick_note_url(@quick_note), params: {
      quick_note: { title: "JSON Updated", content: "JSON content" }
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "JSON Updated", json_response["title"]
  end
  
  test "update should return JSON errors on failure" do
    patch quick_note_url(@quick_note), params: {
      quick_note: { title: "", content: "Content" }
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  # ==========================================================================
  # DESTROY ACTION TESTS
  # ==========================================================================
  
  test "destroy should delete note" do
    sign_in @user
    
    assert_difference("QuickNote.count", -1) do
      delete quick_note_url(@quick_note)
    end
    
    assert_redirected_to quick_notes_path
    assert_equal "Quick note was successfully deleted.", flash[:notice]
  end
  
  test "destroy should return no content for JSON" do
    delete quick_note_url(@quick_note), as: :json
    assert_response :no_content
  end
  
  test "destroy should handle not found" do
    sign_in @user
    
    assert_no_difference("QuickNote.count") do
      delete quick_note_url(id: 999999)
    end
    
    assert_redirected_to quick_notes_path
  end
end
