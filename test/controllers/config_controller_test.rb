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

  # ==========================================================================
  # MARKDOWN RENDERING TESTS
  # ==========================================================================

  test "should render markdown headers as HTML" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_file_url(file: "SOUL.md")
    assert_response :success
    
    # Check that markdown headers are converted to HTML
    assert_select ".markdown-content h1, .markdown-content h2", minimum: 1
  end

  test "should render markdown code blocks" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_file_url(file: "TOOLS.md")
    assert_response :success
    
    # Check for code blocks or inline code
    assert_select ".markdown-content code, .markdown-content pre", minimum: 1
  end

  test "should render markdown lists" do
    skip "Requires asset pipeline" if ENV["CI"]
    get config_file_url(file: "AGENTS.md")
    assert_response :success
    
    # Check for list elements
    assert_select ".markdown-content ul li, .markdown-content ol li", minimum: 1
  end

  test "should render markdown links" do
    skip "Requires asset pipeline" if ENV["CI"]
    # Use HEARTBEAT.md which has external links
    get config_file_url(file: "HEARTBEAT.md")
    assert_response :success
    
    # Links should be rendered as anchor tags
    assert_select ".markdown-content a", minimum: 1
  end

  test "render_markdown helper should convert markdown to HTML" do
    # Test via controller helper method - use send to call private method
    controller = ConfigController.new
    
    # Test header conversion
    html = controller.send(:render_markdown, "# Header 1")
    assert_includes html, "<h1>Header 1</h1>"
    
    # Test bold text
    html = controller.send(:render_markdown, "**bold text**")
    assert_includes html, "<strong>bold text</strong>"
    
    # Test italic text
    html = controller.send(:render_markdown, "*italic text*")
    assert_includes html, "<em>italic text</em>"
    
    # Test code blocks
    html = controller.send(:render_markdown, "```ruby\ncode\n```")
    assert_includes html, "<pre><code class=\"ruby\">"
    
    # Test links have target blank
    html = controller.send(:render_markdown, "[link](http://example.com)")
    assert_includes html, 'target="_blank"'
  end

  test "render_markdown handles empty input" do
    controller = ConfigController.new
    assert_equal "", controller.send(:render_markdown, nil)
    assert_equal "", controller.send(:render_markdown, "")
  end

  test "all whitelisted files are accessible" do
    # Verify all 10 config files can be accessed
    %w[SOUL.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md MEMORY.md IDENTITY.md CHANGELOG.md TEACHING_CODING.md FILE_LOCATIONS.md].each do |filename|
      get config_file_url(file: filename)
      assert_response :success, "Failed to load #{filename}"
      assert_select ".card-header", text: /#{filename}/
    end
  end
end
