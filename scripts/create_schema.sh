#!/usr/bin/env bash
set -e

# Apply schema & seed data on Shard-A
docker exec -i pg-shard-a \
  psql -U repl -d appdb < sql/users_table.sql

# Apply schema & seed data on Shard-B
docker exec -i pg-shard-b \
  psql -U repl -d appdb < sql/users_table.sql

echo "✅ Schema and seed data applied on both shards"