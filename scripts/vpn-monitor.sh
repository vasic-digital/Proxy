#!/usr/bin/env bash
#######################################
# VPN Connection Monitor
# Monitors VPN health and triggers actions on disconnect
#######################################

set -euo pipefail

VPN_AUTO_RECONNECT="${VPN_AUTO_RECONNECT:-true}"
CACHE_INVALIDATE_ON_RECONNECT="${CACHE_INVALIDATE_ON_RECONNECT:-false}"
LAST_STATUS_FILE="/tmp/vpn-last-status"

#######################################
# Log message
#######################################
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VPN-MONITOR] $1"
}

#######################################
# Check VPN connectivity
#######################################
check_vpn() {
    if timeout 10 ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        echo "connected"
    else
        echo "disconnected"
    fi
}

#######################################
# Get last known status
#######################################
get_last_status() {
    if [[ -f "$LAST_STATUS_FILE" ]]; then
        cat "$LAST_STATUS_FILE"
    else
        echo "unknown"
    fi
}

#######################################
# Save current status
#######################################
save_status() {
    echo "$1" > "$LAST_STATUS_FILE"
}

#######################################
# Handle VPN disconnect
#######################################
handle_disconnect() {
    log "WARNING: VPN disconnected!"
    
    if [[ "$CACHE_INVALIDATE_ON_RECONNECT" == "true" ]]; then
        log "Invalidating cache due to VPN disconnect..."
        /invalidator.sh 2>/dev/null || true
    fi
    
    if [[ "$VPN_AUTO_RECONNECT" == "true" ]]; then
        log "Attempting to trigger VPN reconnect..."
        docker restart proxy-vpn 2>/dev/null || true
    fi
}

#######################################
# Handle VPN reconnect
#######################################
handle_reconnect() {
    log "VPN reconnected!"
    
    if [[ "$CACHE_INVALIDATE_ON_RECONNECT" == "true" ]]; then
        log "Invalidating cache after VPN reconnect..."
        /invalidator.sh 2>/dev/null || true
    fi
}

#######################################
# Main monitoring loop
#######################################
main() {
    local current_status
    current_status=$(check_vpn)
    
    local last_status
    last_status=$(get_last_status)
    
    log "Current: $current_status, Last: $last_status"
    
    if [[ "$current_status" == "connected" ]] && [[ "$last_status" == "disconnected" ]]; then
        handle_reconnect
    elif [[ "$current_status" == "disconnected" ]] && [[ "$last_status" == "connected" ]]; then
        handle_disconnect
    fi
    
    save_status "$current_status"
}

main
