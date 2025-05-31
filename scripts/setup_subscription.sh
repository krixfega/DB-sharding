#!/usr/bin/env bash
set -e

# Drop old subscription
docker exec -it pg-shard-b \
  psql -U repl -d appdb -c "DROP SUBSCRIPTION IF EXISTS shard_sub;"

# Create new subscription on Shard-B (streaming + initial copy)
docker exec -it pg-shard-b \
  psql -U repl -d appdb -c "
    CREATE SUBSCRIPTION shard_sub
      CONNECTION 'host=shard-a port=5432 user=repl password=replpass dbname=appdb'
      PUBLICATION shard_pub
      WITH (copy_data = true, streaming = on);
  "

echo "✅ Subscription shard_sub created on Shard-B"