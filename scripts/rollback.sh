#!/usr/bin/env bash
set -e
echo "↩️ Rolling back to Shard-A writes…"

# 1) Remove CUTOVER flag
sed -i.bak '/^CUTOVER=/d' .env

# 2) Restart your dev script
pkill -f "node src/index.js" || true
node src/index.js

echo "✅ Rollback complete; app now dual-writes again"