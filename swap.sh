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
SWAP_PATH=${2:-/usr/swpDSK}

# Convert human-readable size to MB
convert_to_mb() {
    case "$1" in
        *G) echo $((${1%G} * 1024)) ;;  # 4G → 4096
        *M) echo ${1%M} ;;             # 4096M → 4096
        *) echo $1 ;;                  # 4096 → 4096 (assume MB)
    esac
}

# If only a number provided, treat as MB
case "$SWAP_SIZE" in
    *[!0-9]*) : ;;  # already has unit
    *) SWAP_SIZE="${SWAP_SIZE}M" ;;
esac

# Convert to MB for consistent handling
SIZE_MB=$(convert_to_mb "$SWAP_SIZE")

# Get filesystem type
FS_TYPE=$(df -T "$(dirname "$SWAP_PATH")" | awk 'NR==2 {print $2}')

echo "🔍 Checking existing swap configuration..."
EXISTING_SWAP=$(swapon --show=NAME --noheadings | grep -E '^/.*' || true)

# Function to create swap file with filesystem-specific method
create_swap_file() {
    local path=$1
    local size_mb=$2
    
    echo "📁 Creating ${size_mb}MB swap file on $FS_TYPE filesystem..."
    
    # Remove existing file if any
    rm -f "$path"
    
    if [ "$FS_TYPE" = "xfs" ]; then
        echo "⚙️  Using XFS-optimized method..."
        dd if=/dev/zero of="$path" bs=1M count="$size_mb" status=progress
        chattr +C "$path" 2>/dev/null || echo "⚠️  chattr not available, continuing..."
    else
        # Try fallocate first, fall back to dd
        if ! fallocate -l "${size_mb}M" "$path" 2>/dev/null; then
            echo "⚙️  'fallocate' failed — using 'dd' method..."
            dd if=/dev/zero of="$path" bs=1M count="$size_mb" status=progress
        fi
    fi
    
    chmod 600 "$path"
}

# --- If swap already exists ---
if [ -n "$EXISTING_SWAP" ]; then
    echo "✅ Existing swap detected: $EXISTING_SWAP"
    echo "Resizing swap to $SWAP_SIZE (${SIZE_MB}MB)..."

    swapoff "$EXISTING_SWAP" 2>/dev/null || true
    
    # Create new swap file with proper method
    create_swap_file "$EXISTING_SWAP" "$SIZE_MB"
    
    mkswap "$EXISTING_SWAP"
    swapon "$EXISTING_SWAP"

    if ! grep -q "$EXISTING_SWAP" /etc/fstab; then
        echo "$EXISTING_SWAP none swap sw 0 0" | tee -a /etc/fstab
    fi

    echo "✅ Swap resized successfully to $SWAP_SIZE at $EXISTING_SWAP"

# --- No swap found, create new one ---
else
    echo "⚠️ No existing swap detected. Creating new swap at $SWAP_PATH ($SWAP_SIZE - ${SIZE_MB}MB)..."

    # Create new swap file with proper method
    create_swap_file "$SWAP_PATH" "$SIZE_MB"
    
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
