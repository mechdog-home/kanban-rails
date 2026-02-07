# ============================================================================
# Migration: Create API Balance History
# ============================================================================
#
# This table stores periodic snapshots of AI provider API balances.
# Used to track spending and monitor remaining credits over time.
#
# ============================================================================

class CreateApiBalanceHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :api_balance_histories do |t|
      # Provider name (moonshot, anthropic, openai, xai, openrouter)
      t.string :provider, null: false
      
      # Balance information
      t.decimal :balance, precision: 15, scale: 6, null: false, default: 0
      t.string :currency, null: false, default: 'USD'
      
      # Additional metadata (stored as JSON for flexibility)
      t.json :metadata, null: false, default: {}
      
      # Whether the query succeeded
      t.boolean :success, null: false, default: true
      
      # Error message if query failed
      t.text :error_message
      
      # Timestamp of when we queried the API
      t.datetime :queried_at, null: false
      
      t.timestamps
    end
    
    # Index for efficient queries
    add_index :api_balance_histories, [:provider, :queried_at], order: { queried_at: :desc }
    add_index :api_balance_histories, :queried_at
  end
end
