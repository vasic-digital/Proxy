#!/usr/bin/env bash
#######################################
# Cache Invalidation Script
# Removes stale and oversized cache entries
# Can be run standalone or as part of container
#######################################

set -euo pipefail

CACHE_DIR="${CACHE_DIR:-/cache}"
CACHE_MAX_AGE_DAYS="${CACHE_MAX_AGE_DAYS:-30}"
CACHE_MAX_SIZE_GB="${CACHE_MAX_SIZE_GB:-50}"
LOG_FILE="${LOG_FILE:-/var/log/cache-invalidator.log}"

#######################################
# Log message
#######################################
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    if [[ -d "$(dirname "$LOG_FILE")" ]]; then
        echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

#######################################
# Get cache size in KB
#######################################
get_cache_size_kb() {
    du -sk "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0"
}

#######################################
# Get file count
#######################################
get_file_count() {
    find "$CACHE_DIR" -type f 2>/dev/null | wc -l || echo "0"
}

#######################################
# Remove old files
#######################################
remove_old_files() {
    if [[ "$CACHE_MAX_AGE_DAYS" -gt 0 ]]; then
        log "Removing files older than $CACHE_MAX_AGE_DAYS days..."
        local count
        count=$(find "$CACHE_DIR" -type f -mtime +"$CACHE_MAX_AGE_DAYS" -delete -print 2>/dev/null | wc -l)
        log "Removed $count old files"
    fi
}

#######################################
# Remove empty directories
#######################################
remove_empty_dirs() {
    log "Removing empty directories..."
    find "$CACHE_DIR" -type d -empty -delete 2>/dev/null || true
}

#######################################
# Trim cache to size limit
#######################################
trim_cache() {
    local max_kb=$((CACHE_MAX_SIZE_GB * 1024 * 1024))
    local current_kb
    current_kb=$(get_cache_size_kb)
    
    if [[ $current_kb -le $max_kb ]]; then
        log "Cache size ($((current_kb / 1024)) MB) is within limit ($CACHE_MAX_SIZE_GB GB)"
        return 0
    fi
    
    log "Cache over limit: $((current_kb / 1024)) MB > $CACHE_MAX_SIZE_GB GB"
    log "Removing oldest files..."
    
    local removed=0
    while [[ $(get_cache_size_kb) -gt $max_kb ]]; do
        local oldest
        oldest=$(find "$CACHE_DIR" -type f -printf '%A@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2-)
        
        if [[ -z "$oldest" ]]; then
            break
        fi
        
        rm -f "$oldest" 2>/dev/null || true
        ((removed++))
        
        if [[ $((removed % 100)) -eq 0 ]]; then
            log "Removed $removed files so far..."
        fi
    done
    
    log "Removed $removed files to reduce cache size"
}

#######################################
# Invalidate Squid cache
#######################################
invalidate_squid() {
    if command -v squid &>/dev/null; then
        log "Rotating Squid logs..."
        squid -k rotate 2>/dev/null || true
    fi
}

#######################################
# Show final stats
#######################################
show_stats() {
    local size_kb
    size_kb=$(get_cache_size_kb)
    local files
    files=$(get_file_count)
    
    log "Final stats:"
    log "  Cache size: $((size_kb / 1024)) MB"
    log "  Files: $files"
}

#######################################
# Main function
#######################################
main() {
    log "=========================================="
    log "Cache Invalidation Started"
    log "=========================================="
    log "Cache directory: $CACHE_DIR"
    log "Max age: $CACHE_MAX_AGE_DAYS days"
    log "Max size: $CACHE_MAX_SIZE_GB GB"
    
    if [[ ! -d "$CACHE_DIR" ]]; then
        log "ERROR: Cache directory not found: $CACHE_DIR"
        mkdir -p "$CACHE_DIR"
    fi
    
    remove_old_files
    remove_empty_dirs
    trim_cache
    invalidate_squid
    show_stats
    
    log "=========================================="
    log "Cache Invalidation Complete"
    log "=========================================="
}

main "$@"
