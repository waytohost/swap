#!/bin/sh
# ============================================================
# Smart Swap Manager — Auto detect, resize, or create swap
# Works in sh or bash
# Usage:
#   ./swap.sh 8192
#   ./swap.sh 4G
#   ./swap.sh 4G /usr/swpDSK
# ============================================================

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 {size} [path]"
    echo "Example: $0 8192 (MB)"
    echo "Example: $0 4G"
    echo "Optional path: $0 4G /usr/swpDSK"
    exit 1
fi

SWAP_SIZE=$1
SWAP_PATH=${2:-/swapfile}

# If only a number provided, treat as MB
case "$SWAP_SIZE" in
    *[!0-9]*) : ;;  # already has unit
    *) SWAP_SIZE="${SWAP_SIZE}M" ;;
esac

echo "🔍 Checking existing swap configuration..."
EXISTING_SWAP=$(swapon --show=NAME --noheadings | grep -E '^/.*' || true)

# --- If swap already exists ---
if [ -n "$EXISTING_SWAP" ]; then
    echo "✅ Existing swap detected: $EXISTING_SWAP"
    echo "Resizing swap to $SWAP_SIZE..."

    swapoff "$EXISTING_SWAP"

    # Truncate old file first (fix shrinking issue)
    truncate -s 0 "$EXISTING_SWAP"

    # Resize or recreate swap file
    if ! fallocate -l "$SWAP_SIZE" "$EXISTING_SWAP" 2>/dev/null; then
        echo "⚙️  'fallocate' failed — using 'dd' method..."
        SIZE_MB=$(echo "$SWAP_SIZE" | grep -oE '[0-9]+')
        dd if=/dev/zero of="$EXISTING_SWAP" bs=1M count="$SIZE_MB" status=progress
    fi

    chmod 600 "$EXISTING_SWAP"
    mkswap "$EXISTING_SWAP"
    swapon "$EXISTING_SWAP"

    if ! grep -q "$EXISTING_SWAP" /etc/fstab; then
        echo "$EXISTING_SWAP none swap sw 0 0" | tee -a /etc/fstab
    fi

    echo "✅ Swap resized successfully to $SWAP_SIZE at $EXISTING_SWAP"

# --- No swap found, create new one ---
else
    echo "⚠️ No existing swap detected. Creating new swap at $SWAP_PATH ($SWAP_SIZE)..."

    if ! fallocate -l "$SWAP_SIZE" "$SWAP_PATH" 2>/dev/null; then
        echo "⚙️  'fallocate' failed — using 'dd' method..."
        SIZE_MB=$(echo "$SWAP_SIZE" | grep -oE '[0-9]+')
        dd if=/dev/zero of="$SWAP_PATH" bs=1M count="$SIZE_MB" status=progress
    fi

    chmod 600 "$SWAP_PATH"
    mkswap "$SWAP_PATH"
    swapon "$SWAP_PATH"

    if ! grep -q "$SWAP_PATH" /etc/fstab; then
        echo "$SWAP_PATH none swap sw 0 0" | tee -a /etc/fstab
    fi

    echo "✅ Swap created successfully at $SWAP_PATH ($SWAP_SIZE)"
fi

echo
echo "==== Current Swap Info ===="
swapon --show
free -h
echo "=========================="
