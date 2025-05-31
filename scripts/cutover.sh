#!/usr/bin/env bash
set -e
echo "🔀 Cutting over to Shard-B only…"

grep -q "^CUTOVER=" .env && sed -i.bak 's/^CUTOVER=.*/CUTOVER=true/' .env \
  || echo "CUTOVER=true" >> .env

docker exec -it pg-shard-b \
  psql -U repl -d appdb -c "
    SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
  "


pkill -f "node src/index.js" || true
node src/index.js

echo "✅ Cutover complete; app now writes only to Shard-B"