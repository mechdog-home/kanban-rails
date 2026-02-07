# ============================================================================
# API Balance Monitoring Setup
# ============================================================================
#
# This file documents how to set up automated balance monitoring
# for the Kanban Rails application.
#
# ============================================================================

## Overview

The balance monitoring system consists of:

1. **Backend API** (`Api::BalancesController`)
   - GET /api/balances - Current balances from all providers
   - POST /api/balances/refresh - Force refresh and record
   - GET /api/balances/history - Balance history for charting

2. **Balance Service** (`BalanceService`)
   - Queries Moonshot (Kimi) API - supports balance API
   - Queries OpenRouter API - supports balance API
   - OpenAI, Anthropic, xAI - console-only (no public API)

3. **Database Model** (`ApiBalanceHistory`)
   - Stores balance snapshots over time
   - Tracks spending and usage patterns

4. **Frontend Display** (`_balance.html.slim`)
   - Shows at the top of the Kanban board
   - Auto-refreshes every 5 minutes
   - Manual refresh button

## Environment Variables

Ensure these are set in your environment:

```bash
# Required for API balance queries
MOONSHOT_API_KEY=your_key_here
OPENROUTER_API_KEY=your_key_here

# These are used by the gateway but have no balance API
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
XAI_API_KEY=your_key_here
```

## Automated Scheduling (4x Daily)

### Option 1: Cron (Recommended)

Edit your crontab:

```bash
crontab -e
```

Add this line for every 6 hours (00:00, 06:00, 12:00, 18:00):

```cron
0 */6 * * * cd /Users/clawdbot/clawd/kanban-rails && /opt/homebrew/opt/ruby@3.3/bin/ruby bin/rails balances:update RAILS_ENV=production >> log/balance_cron.log 2>&1
```

Or for development:

```cron
0 */6 * * * cd /Users/clawdbot/clawd/kanban-rails && export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH" && bin/rails balances:update >> log/balance_cron.log 2>&1
```

### Option 2: Whenever Gem

Add to Gemfile:

```ruby
gem 'whenever', require: false
```

Install:

```bash
bundle install
bin/wheneverize .
```

Edit `config/schedule.rb`:

```ruby
every 6.hours do
  rake 'balances:update'
end

every 1.day, at: '2:00 am' do
  rake 'balances:cleanup'
end
```

Update crontab:

```bash
bin/whenever --update-crontab
```

### Option 3: macOS LaunchAgent (for Mac)

Create `~/Library/LaunchAgents/com.kanban.balances.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kanban.balances</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/opt/ruby@3.3/bin/ruby</string>
        <string>/Users/clawdbot/clawd/kanban-rails/bin/rails</string>
        <string>balances:update</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/clawdbot/clawd/kanban-rails</string>
    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Hour</key>
            <integer>0</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Hour</key>
            <integer>6</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Hour</key>
            <integer>12</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Hour</key>
            <integer>18</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
    </array>
    <key>StandardOutPath</key>
    <string>/Users/clawdbot/clawd/kanban-rails/log/balance_cron.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/clawdbot/clawd/kanban-rails/log/balance_cron_error.log</string>
</dict>
</plist>
```

Load the agent:

```bash
launchctl load ~/Library/LaunchAgents/com.kanban.balances.plist
launchctl start com.kanban.balances
```

## Manual Commands

```bash
# Check current balances (no recording)
bin/rails balances:check

# Update and record balances
bin/rails balances:update

# View history
bin/rails balances:history

# Clean up old records (keeps 30 days)
bin/rails balances:cleanup
```

## API Usage

```bash
# Get current balances
curl http://localhost:3001/api/balances

# Force refresh
curl -X POST http://localhost:3001/api/balances/refresh

# Get history for charting
curl http://localhost:3001/api/balances/history
curl http://localhost:3001/api/balances/history?provider=moonshot&days=7
```

## Troubleshooting

### No balance data showing
- Check API keys are set: `echo $MOONSHOT_API_KEY`
- Check logs: `tail -f log/development.log`
- Run manually: `bin/rails balances:check`

### Database issues
- Run migrations: `bin/rails db:migrate`
- Check records: `bin/rails console` → `ApiBalanceHistory.count`

### API errors
- Moonshot/Anthropic/OpenAI/xAI/OpenRouter may have console-only balance checking
- Some providers don't offer public balance APIs
- Check API key permissions
