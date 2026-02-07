# ============================================================================
# Rake Task: Update API Balances
# ============================================================================
#
# Queries all AI provider APIs and records balances to the database.
# Intended to be run on a schedule (cron, whenever, etc.)
#
# USAGE:
#   # Run manually
#   rails balances:update
#
#   # Schedule with cron (crontab -e)
#   # Every 6 hours (4 times per day)
#   0 */6 * * * cd /path/to/app && /usr/bin/env bin/rails balances:update RAILS_ENV=production
#
#   # Or use the whenever gem
#
# ============================================================================

namespace :balances do
  desc "Query all AI provider APIs and record balances to database"
  task update: :environment do
    puts "[#{Time.current}] Starting balance update..."
    
    begin
      results = BalanceService.record_balances!
      
      puts "\nBalance Update Results:"
      puts "=" * 50
      
      results.each do |provider, data|
        status = data[:success] ? '✓' : '✗'
        name = data[:name] || provider.to_s.titleize
        
        if data[:success]
          if data[:supports_api] == false
            puts "#{status} #{name}: Console-only (no API)"
          elsif data[:balance].present?
            currency = data[:currency] || 'USD'
            symbol = currency == 'CNY' ? '¥' : '$'
            puts "#{status} #{name}: #{symbol}#{data[:balance].round(2)} #{currency}"
          else
            puts "#{status} #{name}: Unknown balance"
          end
        else
          puts "#{status} #{name}: ERROR - #{data[:error]}"
        end
      end
      
      puts "=" * 50
      puts "Recorded #{ApiBalanceHistory.count} total history entries"
      puts "[#{Time.current}] Balance update complete!"
      
    rescue => e
      puts "ERROR: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end
  
  desc "Show current balances without recording to database"
  task check: :environment do
    puts "[#{Time.current}] Checking current balances..."
    
    results = BalanceService.query_all
    
    puts "\nCurrent Balances:"
    puts "=" * 50
    
    results.each do |provider, data|
      name = data[:name] || provider.to_s.titleize
      
      if data[:success]
        if data[:supports_api] == false
          puts "#{name}: Console-only"
          puts "  → #{data[:note]}" if data[:note]
        elsif data[:balance].present?
          currency = data[:currency] || 'USD'
          symbol = currency == 'CNY' ? '¥' : '$'
          puts "#{name}: #{symbol}#{data[:balance].round(2)} #{currency}"
          puts "  Total: #{symbol}#{data[:total_credits].round(2)}" if data[:total_credits]
          puts "  Used: #{symbol}#{data[:total_usage].round(2)}" if data[:total_usage]
        else
          puts "#{name}: Available (balance hidden)"
        end
      else
        puts "#{name}: ERROR - #{data[:error]}"
      end
      puts
    end
    
    puts "=" * 50
  end
  
  desc "Show balance history summary"
  task history: :environment do
    puts "[#{Time.current}] Balance History Summary"
    puts "=" * 60
    
    ApiBalanceHistory::PROVIDERS.each do |provider|
      records = ApiBalanceHistory.for_provider(provider).successful.recent.limit(5)
      
      if records.any?
        puts "\n#{provider.titleize}:"
        records.each do |record|
          symbol = record.currency == 'CNY' ? '¥' : '$'
          puts "  #{record.queried_at.strftime('%Y-%m-%d %H:%M')} - #{symbol}#{record.balance.round(2)}"
        end
        
        # Show usage stats if we have enough data
        stats = ApiBalanceHistory.usage_stats(provider, 7)
        if stats
          spent = stats[:spent]
          symbol = stats[:end_balance] > 1000 ? '¥' : '$'
          puts "  → Spent #{symbol}#{spent.round(2)} over #{stats[:days_tracked].round(1)} days"
        end
      else
        puts "\n#{provider.titleize}: No recorded data"
      end
    end
    
    puts "\n" + "=" * 60
    puts "Total history records: #{ApiBalanceHistory.count}"
  end
  
  desc "Clean up old balance history (keeps last 30 days)"
  task cleanup: :environment do
    cutoff = 30.days.ago
    old_records = ApiBalanceHistory.where('queried_at < ?', cutoff)
    count = old_records.count
    
    if count > 0
      old_records.destroy_all
      puts "Deleted #{count} old balance records (older than #{cutoff.strftime('%Y-%m-%d')})"
    else
      puts "No old records to clean up"
    end
    
    puts "Remaining records: #{ApiBalanceHistory.count}"
  end
end
