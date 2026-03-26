#!/usr/bin/env bash
#######################################
# Cache Invalidation Script
# Removes stale and oversized cache entries
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/container-runtime.sh"

CACHE_DIR="${CACHE_DIR:-./cache}"
CACHE_MAX_AGE_DAYS="${CACHE_MAX_AGE_DAYS:-30}"
CACHE_MAX_SIZE_GB="${CACHE_MAX_SIZE_GB:-50}"

log "info" "Starting cache invalidation..."
log "info" "Cache directory: $CACHE_DIR"
log "info" "Max age: $CACHE_MAX_AGE_DAYS days"
log "info" "Max size: $CACHE_MAX_SIZE_GB GB"

# Remove files older than max age
if [[ "$CACHE_MAX_AGE_DAYS" -gt 0 ]]; then
    log "info" "Removing files older than $CACHE_MAX_AGE_DAYS days..."
    find "$CACHE_DIR" -type f -mtime +$CACHE_MAX_AGE_DAYS -delete 2>/dev/null || true
fi

# Remove empty directories
log "info" "Cleaning empty directories..."
find "$CACHE_DIR" -type d -empty -delete 2>/dev/null || true

# Check cache size and remove oldest files if over limit
current_size_kb=$(du -sk "$CACHE_DIR" 2>/dev/null | cut -f1)
max_size_kb=$((CACHE_MAX_SIZE_GB * 1024 * 1024))

if [[ $current_size_kb -gt $max_size_kb ]]; then
    log "warn" "Cache over size limit: ${current_size_kb}KB > ${max_size_kb}KB"
    log "info" "Removing oldest files to reduce size..."
    
    # List files by access time, oldest first, and remove until under limit
    while [[ $current_size_kb -gt $max_size_kb ]]; do
        oldest_file=$(find "$CACHE_DIR" -type f -printf '%A@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2-)
        if [[ -z "$oldest_file" ]]; then
            break
        fi
        rm -f "$oldest_file"
        current_size_kb=$(du -sk "$CACHE_DIR" 2>/dev/null | cut -f1)
    done
fi

log "info" "Cache invalidation complete"
get_cache_stats
