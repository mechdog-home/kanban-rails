# ============================================================================
# View Tests: Kanban Board Layout
# ============================================================================
#
# LEARNING NOTES:
#
# These tests verify the kanban board renders with the correct layout.
# Specifically, we test that Sparky's swim lane appears before MechDog's
# for better visibility (Task #50).
#
# WHY THIS MATTERS:
# -----------------
# The order of swim lanes affects user experience. Sparky needs to see
# their tasks prominently at the top of the board.
#
# TEST STRATEGY:
# --------------
# We render the full index view and verify the DOM order of swim lanes.
# Sparky's lane should appear before MechDog's in the HTML.
#
# ============================================================================

require "test_helper"

class KanbanBoardLayoutTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    # Create a test user and sign in before each test
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser",
      name: "Test User",
      role: "user"
    )
    sign_in @user

    # Create tasks for both assignees
    @sparky_task = Task.create!(
      title: "Sparky Task",
      description: "A task for Sparky",
      assignee: "sparky",
      status: "in_progress",
      priority: "high"
    )

    @mechdog_task = Task.create!(
      title: "MechDog Task",
      description: "A task for MechDog",
      assignee: "mechdog",
      status: "backlog",
      priority: "medium"
    )
  end

  # ==========================================================================
  # SWIM LANE ORDER TESTS
  # ==========================================================================

  test "sparky swim lane appears before mechdog swim lane" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Find the positions of each swim lane ELEMENT in the HTML (not CSS definitions)
    # We search for the actual element class attribute: class="swim-lane swim-lane-sparky"
    # Using the quote helps distinguish from CSS class definitions like .swim-lane-sparky
    sparky_position = @response.body.index('swim-lane-sparky"')
    mechdog_position = @response.body.index('swim-lane-mechdog"')
    
    # Both should be present
    assert_not_nil sparky_position, "Sparky swim lane should be present"
    assert_not_nil mechdog_position, "MechDog swim lane should be present"
    
    # Sparky should come before MechDog (lower index = earlier in HTML)
    assert sparky_position < mechdog_position,
           "Sparky's swim lane should appear before MechDog's swim lane"
  end

  test "sparky column headers appear before mechdog column headers" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Check for column-specific IDs to verify order
    # Each column has an id like "column_sparky_backlog" or "column_mechdog_backlog"
    sparky_backlog_pos = @response.body.index('id="column_sparky_backlog"')
    mechdog_backlog_pos = @response.body.index('id="column_mechdog_backlog"')
    
    assert_not_nil sparky_backlog_pos, "Sparky backlog column should be present"
    assert_not_nil mechdog_backlog_pos, "MechDog backlog column should be present"
    assert sparky_backlog_pos < mechdog_backlog_pos,
           "Sparky's backlog column should appear before MechDog's"
  end

  test "kanban board renders with all expected swim lanes" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Should have both assignee swim lanes
    assert_includes @response.body, 'swim-lane-sparky'
    assert_includes @response.body, 'swim-lane-mechdog'
    
    # Should have headers for both assignees
    assert_includes @response.body, 'Sparky'
    assert_includes @response.body, 'Mechdog'
  end

  test "each swim lane contains all status columns" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Each assignee should have all 6 status columns
    Task::ASSIGNEES.each do |assignee|
      Task::STATUSES.each do |status|
        column_id = "id=\"column_#{assignee}_#{status}\""
        assert_includes @response.body, column_id,
                       "Column #{column_id} should be present for #{assignee}"
      end
    end
  end

  test "sparky tasks appear in sparky's columns" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Find the sparky in_progress column
    column_start = @response.body.index('id="column_sparky_in_progress"')
    assert_not_nil column_start, "Sparky in_progress column should exist"
    
    # Find the next column to limit our search scope
    next_column = @response.body.index('id="column_sparky_sprint"')
    column_end = next_column || @response.body.length
    
    # Extract just the sparky in_progress column content
    column_content = @response.body[column_start...column_end]
    
    # The task should be in this column
    assert_includes column_content, @sparky_task.title,
                   "Sparky's task should appear in Sparky's in_progress column"
  end

  test "mechdog tasks appear in mechdog's columns" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Find the mechdog backlog column
    column_start = @response.body.index('id="column_mechdog_backlog"')
    assert_not_nil column_start, "MechDog backlog column should exist"
    
    # Find the next column to limit our search scope
    next_column = @response.body.index('id="column_mechdog_in_progress"')
    column_end = next_column || @response.body.length
    
    # Extract just the mechdog backlog column content
    column_content = @response.body[column_start...column_end]
    
    # The task should be in this column
    assert_includes column_content, @mechdog_task.title,
                   "MechDog's task should appear in MechDog's backlog column"
  end

  # ==========================================================================
  # MOBILE RESPONSIVENESS TESTS
  # ==========================================================================

  test "board uses responsive column classes" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Each column should use col-md-2 (6 columns per row on medium+ screens)
    # This ensures proper layout on desktop while stacking on mobile
    assert_includes @response.body, 'col-md-2'
    
    # Should have container-fluid for full-width responsive container
    assert_includes @response.body, 'container-fluid'
  end

  test "columns stack on mobile with row and col classes" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Verify Bootstrap grid structure for responsive stacking
    # On mobile: columns stack vertically (no col-* class = full width)
    # On medium+: col-md-2 creates 6 columns per row
    assert_includes @response.body, 'row'
    assert_includes @response.body, 'g-3'  # Gap between columns
  end

  # ==========================================================================
  # DRAG AND DROP DATA ATTRIBUTES
  # ==========================================================================

  test "columns have correct data attributes for drag and drop" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Columns need data-sortable-target="column" for the Stimulus controller
    assert_includes @response.body, 'data-sortable-target="column"'
    
    # Each column should have data-status and data-assignee
    assert_includes @response.body, 'data-status="backlog"'
    assert_includes @response.body, 'data-assignee="sparky"'
    assert_includes @response.body, 'data-assignee="mechdog"'
  end

  # ==========================================================================
  # VISUAL STYLING TESTS
  # ==========================================================================

  test "swim lanes have distinct styling classes" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Each swim lane should have its own styling class
    assert_includes @response.body, 'swim-lane-sparky'
    assert_includes @response.body, 'swim-lane-mechdog'
    
    # Should have the base swim-lane class
    assert_includes @response.body, 'swim-lane'
  end

  test "column count badges are present for all columns" do
    skip "Requires asset pipeline" if ENV["CI"]
    
    get tasks_url
    assert_response :success
    
    # Each column should have a count badge with id like "count_sparky_backlog"
    assert_includes @response.body, 'id="count_sparky_backlog"'
    assert_includes @response.body, 'id="count_mechdog_backlog"'
    assert_includes @response.body, 'column-count'  # CSS class for count
  end
end
