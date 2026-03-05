class CreateUsageSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_snapshots do |t|
      t.decimal :daily_remaining
      t.decimal :weekly_remaining
      t.integer :total_used
      t.integer :session_count
      t.string :ai_model
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
