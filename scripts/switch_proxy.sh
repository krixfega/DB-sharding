#!/usr/bin/env bash
set -e

# Directory where proxy configs live on host
PROXY_DIR="$(dirname "$0")/../proxy"

if [ "$1" != "A" ] && [ "$1" != "B" ]; then
  echo "Usage: $0 A|B"
  exit 1
fi

echo "🔀 Switching proxy to shard-$1..."

# Update the symlink on the host in the proxy directory
if [ "$1" = "A" ]; then
  (cd "$PROXY_DIR" && ln -sf haproxy-a.cfg haproxy.cfg)
else
  (cd "$PROXY_DIR" && ln -sf haproxy-b.cfg haproxy.cfg)
fi

echo "🔄 Restarting HAProxy container to apply new configuration..."
# Restart the proxy container so it picks up the updated config
docker restart pg-proxy > /dev/null

# Wait a few seconds for HAProxy to start
sleep 2

# Validate that HAProxy is running with the new config
docker exec pg-proxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

if [ $? -eq 0 ]; then
  echo "✅ Proxy switched to shard-$1"
else
  echo "❌ Failed to start HAProxy with the new configuration"
  exit 1
fi