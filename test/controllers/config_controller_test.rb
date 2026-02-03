# ============================================================================
# Controller Tests: ConfigController
# ============================================================================
#
# LEARNING NOTES:
#
# Tests for the config file viewer controller.
# These are read-only endpoints that don't require authentication.
#
# KEY CONCEPTS:
# - Integration tests simulate HTTP requests
# - Config viewer is public (no login required)
# - Tests verify file listing and content rendering
#
# ============================================================================

require "test_helper"

class ConfigControllerTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # INDEX TESTS
  # ==========================================================================

  test "should get index without authentication" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_url
    assert_response :success
    assert_select "title", "Config Viewer"
    assert_select ".list-group-item", minimum: 5  # Should show file list
  end

  test "index should show file list" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_url
    assert_response :success
    
    # Check for expected config files in sidebar
    assert_select ".list-group-item", text: /Soul/
    assert_select ".list-group-item", text: /Agents/
    assert_select ".list-group-item", text: /User/
    assert_select ".list-group-item", text: /Tools/
    assert_select ".list-group-item", text: /Memory/
  end

  # ==========================================================================
  # SHOW TESTS
  # ==========================================================================

  test "should show specific config file" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_file_url(file: "SOUL.md")
    assert_response :success
    assert_select "title", "Config Viewer"
    # Content is rendered via JavaScript, but page structure should exist
    assert_select ".markdown-content"
    assert_select ".card-header", text: /SOUL.md/
  end

  test "should show AGENTS.md file" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_file_url(file: "AGENTS.md")
    assert_response :success
    assert_select ".card-header", text: /AGENTS.md/
  end

  test "should show TOOLS.md file" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_file_url(file: "TOOLS.md")
    assert_response :success
    assert_select ".card-header", text: /TOOLS.md/
  end

  test "should redirect for unknown file" do
    get config_file_url(file: "UNKNOWN.md")
    assert_redirected_to config_path
    assert_equal "File not found", flash[:alert]
  end

  test "should block path traversal attempts via route constraint" do
    # Route constraint rejects paths with slashes before they reach controller
    assert_raises(ActionController::UrlGenerationError) do
      get config_file_url(file: "../Gemfile")
    end
  end

  test "should block malicious path traversal via route constraint" do
    # Route constraint rejects paths with slashes before they reach controller
    assert_raises(ActionController::UrlGenerationError) do
      get config_file_url(file: "../../../etc/passwd")
    end
  end
  
  test "should handle file not in whitelist gracefully" do
    get config_file_url(file: "SECRET.md")
    assert_redirected_to config_path
    assert_equal "File not found", flash[:alert]
  end

  # ==========================================================================
  # API TESTS
  # ==========================================================================

  test "should return JSON file list via API" do
    get config_files_url
    assert_response :success
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.length >= 5
    
    # Check structure
    file = json.first
    assert file["id"]
    assert file["name"]
    assert file["label"]
    assert file["description"]
  end

  test "API file list includes SOUL.md" do
    get config_files_url
    json = JSON.parse(response.body)
    
    soul_file = json.find { |f| f["name"] == "SOUL.md" }
    assert soul_file
    assert_equal "Soul", soul_file["label"]
    assert_equal "Who Sparky is", soul_file["description"]
  end
end
