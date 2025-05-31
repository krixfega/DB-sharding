#!/usr/bin/env bash
#
# scripts/health_check.sh
#
# Simple health check that:
# 1) Queries Shard-B (subscriber) for replication lag.
# 2) If lag < MAX_LAG_SECONDS and proxy currently points to A, flip to B.
# 3) If lag >= MAX_LAG_SECONDS (or subscriber is down) and proxy currently points to B, flip to A.
#
# Usage:
#   ./scripts/health_check.sh
#
# To run periodically via cron, add a crontab line such as:
#   */1 * * * * cd /Users/chris/Downloads/DB-sharding && ./scripts/health_check.sh >> health.log 2>&1
#

set -euo pipefail

# Maximum allowable lag (in seconds) to consider Shard-B “healthy.” Adjust as needed.
MAX_LAG_SECONDS=0.5

# ------------------------------------------------------------------------------
# get_replication_lag: returns the lag (in seconds) between last_msg_recv_time and
#                     last_msg_send_time on Shard-B. If no row or invalid, returns empty string.
# ------------------------------------------------------------------------------
get_replication_lag() {
  docker exec pg-shard-b psql -U repl -d appdb -Atq \
    -c "
      SELECT
        EXTRACT(
          EPOCH FROM
          (last_msg_receipt_time - last_msg_send_time)
        ) AS lag_seconds
      FROM pg_stat_subscription
      WHERE subname = 'shard_sub';
    " 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# is_replication_active: returns 0 (true) if the subscription worker on Shard-B
#                        is running (i.e. pid IS NOT NULL). Else returns 1 (false).
# ------------------------------------------------------------------------------
is_replication_active() {
  local pid
  pid=$(docker exec pg-shard-b psql -U repl -d appdb -Atq \
    -c "SELECT pid FROM pg_stat_subscription WHERE subname = 'shard_sub';" 2>/dev/null || true)

  if [[ -n "$pid" && "$pid" != "null" ]]; then
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------
# get_current_proxy: inspects the host‐side symlink at proxy/haproxy.cfg and
#                    echoes "A" if it points to haproxy-a.cfg, else "B".
# ------------------------------------------------------------------------------
get_current_proxy() {
  local target
  # The symlink is in our host folder, not inside Docker.
  # Example output: "haproxy.cfg -> haproxy-b.cfg"
  target=$(ls -l proxy/haproxy.cfg 2>/dev/null || true)

  if [[ $target =~ haproxy-b\.cfg ]]; then
    echo "B"
  else
    echo "A"
  fi
}

# ------------------------------------------------------------------------------
# switch_proxy: calls our existing switch_proxy.sh to swap HAProxy to target A or B.
# ------------------------------------------------------------------------------
switch_proxy() {
  local to="$1"
  echo "$(date -u) │ switching proxy to shard-$to..."
  scripts/switch_proxy.sh "$to"
}

# ------------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------------
{
  # 1) Check if Shard-B’s subscription worker is running. If not, treat lag as “infinite”:
  if is_replication_active; then
    raw_lag=$(get_replication_lag)
    # If raw_lag is not a floating‐point number, set it to a large value to indicate “unhealthy”.
    if [[ ! $raw_lag =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      raw_lag=""
    fi
  else
    raw_lag=""
  fi

  if [[ -z "$raw_lag" ]]; then
    # No subscription row or worker down → treat as “unhealthy”
    lag_value=9999
  else
    # Convert to plain number
    lag_value="$raw_lag"
  fi

  echo "$(date -u) │ Shard-B replication lag = ${lag_value} seconds"

  # 2) Compare lag_value to MAX_LAG_SECONDS via bc (floating-point compare)
  lag_ok=$(echo "$lag_value < $MAX_LAG_SECONDS" | bc -l)  # yields "1" if true, "0" if false

  # 3) Determine where HAProxy is currently pointing
  current=$(get_current_proxy)

  if [[ "$lag_ok" -eq 1 ]]; then
    # Shard-B is healthy
    if [[ "$current" == "A" ]]; then
      switch_proxy B
    else
      echo "$(date -u) │ Proxy already pointing to Shard-B"
    fi
  else
    # Shard-B is unhealthy
    if [[ "$current" == "B" ]]; then
      switch_proxy A
    else
      echo "$(date -u) │ Proxy already pointing to Shard-A"
    fi
  fi
}  # End MAIN

exit 0