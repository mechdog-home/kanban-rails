# ============================================================================
# Model Tests: QuickNote
# ============================================================================
#
# LEARNING NOTES:
#
# Model tests verify that our QuickNote model works correctly.
# We test validations, scopes, and instance methods.
#
# RUNNING TESTS:
#   bin/rails test test/models/quick_note_test.rb
#
# ============================================================================

require "test_helper"

class QuickNoteTest < ActiveSupport::TestCase
  # ==========================================================================
  # FIXTURES
  # ==========================================================================
  #
  # We create test records programmatically instead of relying on fixtures
  # This makes tests more readable and self-contained
  
  def setup
    @valid_attributes = {
      title: "Test Note Title",
      content: "This is the content of the test note."
    }
  end

  # ==========================================================================
  # VALIDATION TESTS
  # ==========================================================================
  
  test "should be valid with valid attributes" do
    note = QuickNote.new(@valid_attributes)
    assert note.valid?, "QuickNote should be valid with title and content"
  end
  
  test "should be valid without content" do
    note = QuickNote.new(title: "Title Only")
    assert note.valid?, "QuickNote should be valid without content"
  end
  
  test "should be invalid without title" do
    note = QuickNote.new(content: "Content without title")
    assert_not note.valid?, "QuickNote should be invalid without title"
    assert_includes note.errors[:title], "can't be blank"
  end
  
  test "should enforce title maximum length" do
    note = QuickNote.new(title: "a" * 256)
    assert_not note.valid?, "QuickNote should be invalid with title > 255 chars"
    assert_includes note.errors[:title], "is too long (maximum is 255 characters)"
  end
  
  test "should enforce content maximum length" do
    note = QuickNote.new(title: "Valid Title", content: "a" * 10001)
    assert_not note.valid?, "QuickNote should be invalid with content > 10000 chars"
    assert_includes note.errors[:content], "is too long (maximum is 10000 characters)"
  end

  # ==========================================================================
  # SCOPE TESTS
  # ==========================================================================
  
  test "recent scope should order by updated_at desc" do
    # Create notes in specific order
    old_note = QuickNote.create!(title: "Old Note", updated_at: 2.days.ago)
    new_note = QuickNote.create!(title: "New Note", updated_at: 1.hour.ago)
    
    result = QuickNote.recent.to_a
    assert_equal new_note, result.first, "Recent should return newest first"
    assert_equal old_note, result.last, "Recent should return oldest last"
  end
  
  test "newest scope should order by created_at desc" do
    old_note = QuickNote.create!(title: "Old Note", created_at: 2.days.ago)
    new_note = QuickNote.create!(title: "New Note", created_at: 1.hour.ago)
    
    result = QuickNote.newest.to_a
    assert_equal new_note, result.first, "Newest should return most recently created first"
  end
  
  test "this_week scope should return notes from last 7 days" do
    recent = QuickNote.create!(title: "Recent", updated_at: 2.days.ago)
    old = QuickNote.create!(title: "Old", updated_at: 10.days.ago)
    
    result = QuickNote.this_week
    assert_includes result, recent, "This week should include recent note"
    assert_not_includes result, old, "This week should not include old note"
  end
  
  test "today scope should return notes from last 24 hours" do
    today = QuickNote.create!(title: "Today", updated_at: 2.hours.ago)
    yesterday = QuickNote.create!(title: "Yesterday", updated_at: 25.hours.ago)
    
    result = QuickNote.today
    assert_includes result, today, "Today should include note from 2 hours ago"
    assert_not_includes result, yesterday, "Today should not include note from 25 hours ago"
  end
  
  test "search scope should find by title" do
    note = QuickNote.create!(title: "Important Meeting", content: "Details")
    
    result = QuickNote.search("Meeting")
    assert_includes result, note, "Search should find by title"
  end
  
  test "search scope should find by content" do
    note = QuickNote.create!(title: "Note", content: "Remember to buy milk")
    
    result = QuickNote.search("milk")
    assert_includes result, note, "Search should find by content"
  end

  # ==========================================================================
  # CLASS METHOD TESTS
  # ==========================================================================
  
  test "recent_for_board should return specified number of notes" do
    5.times { |i| QuickNote.create!(title: "Note #{i}") }
    
    assert_equal 3, QuickNote.recent_for_board(3).count
    assert_equal 5, QuickNote.recent_for_board(10).count
  end
  
  test "recent_for_board default limit is 5" do
    7.times { |i| QuickNote.create!(title: "Note #{i}") }
    
    assert_equal 5, QuickNote.recent_for_board.count
  end
  
  test "total_count returns correct count" do
    initial_count = QuickNote.count
    QuickNote.create!(title: "New Note")
    
    assert_equal initial_count + 1, QuickNote.total_count
  end
  
  test "created_today_count returns notes created today" do
    QuickNote.create!(title: "Today", created_at: Time.current)
    QuickNote.create!(title: "Yesterday", created_at: 1.day.ago)
    
    assert_equal 1, QuickNote.created_today_count
  end

  # ==========================================================================
  # INSTANCE METHOD TESTS
  # ==========================================================================
  
  test "edited? returns false for new note" do
    note = QuickNote.create!(@valid_attributes)
    assert_not note.edited?, "New note should not show as edited"
  end
  
  test "edited? returns true after update" do
    note = QuickNote.create!(@valid_attributes)
    sleep 0.1  # Ensure time difference
    note.update!(content: "Updated content")
    
    assert note.edited?, "Updated note should show as edited"
  end
  
  test "time_since_update returns 'Just now' for recent updates" do
    note = QuickNote.create!(@valid_attributes)
    assert_equal "Just now", note.time_since_update
  end
  
  test "preview returns truncated content" do
    note = QuickNote.new(title: "Test", content: "a" * 200)
    preview = note.preview(50)
    
    assert_equal 53, preview.length, "Preview should be truncated with ellipsis"
    assert preview.end_with?("..."), "Preview should end with ellipsis"
  end
  
  test "preview returns full content when shorter than length" do
    note = QuickNote.new(title: "Test", content: "Short content")
    assert_equal "Short content", note.preview(100)
  end
  
  test "preview returns empty string for blank content" do
    note = QuickNote.new(title: "Test")
    assert_equal "", note.preview(100)
  end
  
  test "age_category returns :fresh for notes less than 24 hours old" do
    note = QuickNote.new(title: "Test", updated_at: 30.minutes.ago)
    assert_equal :fresh, note.age_category
  end
  
  test "age_category returns :recent for notes 1-3 days old" do
    note = QuickNote.new(title: "Test", updated_at: 2.days.ago)
    assert_equal :recent, note.age_category
  end
  
  test "age_category returns :week_old for notes 3-7 days old" do
    note = QuickNote.new(title: "Test", updated_at: 5.days.ago)
    assert_equal :week_old, note.age_category
  end
  
  test "age_category returns :old for notes older than a week" do
    note = QuickNote.new(title: "Test", updated_at: 10.days.ago)
    assert_equal :old, note.age_category
  end
  
  test "age_css_class returns border-info for fresh notes" do
    note = QuickNote.new(title: "Test", updated_at: 30.minutes.ago)
    assert_equal "border-info", note.age_css_class
  end
  
  test "age_css_class returns border-success for recent notes" do
    note = QuickNote.new(title: "Test", updated_at: 2.days.ago)
    assert_equal "border-success", note.age_css_class
  end
  
  test "age_css_class returns border-warning for week_old notes" do
    note = QuickNote.new(title: "Test", updated_at: 5.days.ago)
    assert_equal "border-warning", note.age_css_class
  end
  
  test "age_css_class returns border-secondary for old notes" do
    note = QuickNote.new(title: "Test", updated_at: 10.days.ago)
    assert_equal "border-secondary", note.age_css_class
  end
end
