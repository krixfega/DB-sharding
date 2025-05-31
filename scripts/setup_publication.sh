#!/usr/bin/env bash
set -e

# Drop & create publication on Shard-A
docker exec -it pg-shard-a \
  psql -U repl -d appdb -c "
    DROP PUBLICATION IF EXISTS shard_pub;
    CREATE PUBLICATION shard_pub FOR TABLE users;
  "

echo "✅ Publication shard_pub created on Shard-A"