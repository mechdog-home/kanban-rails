#!/bin/bash
# ============================================================================
# Setup Script: Balance Monitoring LaunchAgent
# ============================================================================
#
# Installs the macOS LaunchAgent for automated balance monitoring.
# Run 4 times per day: 00:00, 06:00, 12:00, 18:00
#
# Usage:
#   ./script/setup_balance_monitoring.sh
#
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLIST_NAME="com.mechdog.kanban-balances.plist"
PLIST_SOURCE="${SCRIPT_DIR}/${PLIST_NAME}"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_DEST="${LAUNCH_AGENTS_DIR}/${PLIST_NAME}"

echo "Setting up Balance Monitoring LaunchAgent..."
echo "=================================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is for macOS only."
    echo "For Linux, use cron instead:"
    echo "  0 */6 * * * cd $(dirname "$SCRIPT_DIR") && bin/rails balances:update"
    exit 1
fi

# Create LaunchAgents directory if needed
mkdir -p "$LAUNCH_AGENTS_DIR"

# Copy plist file
cp "$PLIST_SOURCE" "$PLIST_DEST"
echo "✓ Installed ${PLIST_NAME} to ${LAUNCH_AGENTS_DIR}"

# Unload existing agent if present
if launchctl list | grep -q "com.mechdog.kanban-balances"; then
    echo "Unloading existing agent..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Load the agent
echo "Loading LaunchAgent..."
launchctl load "$PLIST_DEST"

# Verify
echo ""
echo "Verifying installation..."
if launchctl list | grep -q "com.mechdog.kanban-balances"; then
    echo "✓ LaunchAgent loaded successfully"
else
    echo "✗ Failed to load LaunchAgent"
    exit 1
fi

echo ""
echo "=================================================="
echo "Setup complete!"
echo ""
echo "The balance monitor will run:"
echo "  - Every 6 hours (00:00, 06:00, 12:00, 18:00)"
echo ""
echo "Logs:"
echo "  - Output: $(dirname "$SCRIPT_DIR")/log/balance_cron.log"
echo "  - Errors: $(dirname "$SCRIPT_DIR")/log/balance_cron_error.log"
echo ""
echo "Commands:"
echo "  launchctl list | grep kanban-balances  # Check status"
echo "  launchctl unload ~/Library/LaunchAgents/${PLIST_NAME}  # Stop"
echo "  launchctl load ~/Library/LaunchAgents/${PLIST_NAME}    # Start"
echo "  launchctl start com.mechdog.kanban-balances            # Run now"
echo ""
echo "To test manually:"
echo "  cd $(dirname "$SCRIPT_DIR") && bin/rails balances:update"
