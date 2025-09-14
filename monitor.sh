#!/bin/bash
# monitor.sh - Server monitor with general webhook
# Version: 4.0

### === LOAD CONFIG (.env) === ###
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
else
    echo "❌ .env file not found in $SCRIPT_DIR"
    exit 1
fi

# Auto-detect hostname
HOSTNAME=$(hostname)

# State files
STATE_FILE="$SCRIPT_DIR/.monitor_state"
LAST_BOOT_FILE="$SCRIPT_DIR/.last_boot"
LAST_NOTIFY_FILE="$SCRIPT_DIR/.last_notify"

### === FUNCTIONS === ###

send_webhook() {
    local subject="$1"
    local message="$2"
    local date=$(date +"%Y-%m-%d")
    local time=$(date +"%H:%M:%S")

    # Send JSON payload to general webhook
    curl -s -X POST "$WEBHOOK_URL" \
         -H "Content-Type: application/json" \
         -d "{
            \"date\": \"$date\",
            \"time\": \"$time\",
            \"subject\": \"$subject\",
            \"message\": \"$message\",
            \"server\": \"$HOSTNAME\"
         }" >/dev/null

    # Update last notification timestamp
    echo "$(date +%s)" > "$LAST_NOTIFY_FILE"
}

### === CHECK FUNCTIONS === ###

check_network() {
    if ! ping -c1 -W2 "$CHECK_HOST" >/dev/null 2>&1; then
        if [ "$(cat "$STATE_FILE" 2>/dev/null)" != "netdown" ]; then
            send_webhook "Network Down" "⚠️ $HOSTNAME: Cannot reach $CHECK_HOST"
            echo "netdown" > "$STATE_FILE"
        fi
    else
        echo "netok" > "$STATE_FILE"
    fi
}

check_reboot() {
    local last_boot prev_boot
    last_boot=$(who -b | awk '{print $3,$4}')
    prev_boot=$(cat "$LAST_BOOT_FILE" 2>/dev/null)

    if [ "$last_boot" != "$prev_boot" ]; then
        send_webhook "Reboot" "♻️ $HOSTNAME reboot detected (boot at $last_boot)"
        echo "$last_boot" > "$LAST_BOOT_FILE"
    fi
}

check_disk() {
    local usage
    usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$usage" -ge "$DISK_WARN" ]; then
        send_webhook "Disk Usage High" "💾 $HOSTNAME: Disk usage is ${usage}%"
    fi
}

check_memory() {
    local free
    free=$(free | awk '/Mem:/ {printf("%.0f", $4/$2 * 100)}')
    if [ "$free" -le "$MEM_WARN" ]; then
        send_webhook "Low Memory" "🧠 $HOSTNAME: Only ${free}% memory free"
    fi
}

check_load() {
    local load
    load=$(awk '{print int($1)}' /proc/loadavg)
    if [ "$load" -ge "$LOAD_WARN" ]; then
        send_webhook "High Load" "🔥 $HOSTNAME: Load average is $load"
    fi
}

check_heartbeat() {
    local now last_notify diff
    now=$(date +%s)
    last_notify=$(cat "$LAST_NOTIFY_FILE" 2>/dev/null || echo 0)
    diff=$(( (now - last_notify) / 86400 ))   # days

    if [ "$diff" -ge 30 ]; then
        send_webhook "Health Check" "✅ $HOSTNAME monitoring still running (no alerts for $diff days)"
    fi
}

### === MAIN === ###
check_network
check_reboot
check_disk
check_memory
check_load
check_heartbeat
