import { poolA, poolB, primary } from './db.js';

export async function createUser(name, email) {
  if (process.env.CUTOVER !== 'true') {
    const { rows: [a] } = await poolA.query(
      `INSERT INTO users (name,email) VALUES ($1,$2) RETURNING id,created_at;`,
      [name, email]
    );
    await poolB.query(
      `INSERT INTO users (id,name,email,created_at)
       VALUES ($1,$2,$3,$4) ON CONFLICT DO NOTHING;`,
      [a.id, name, email, a.created_at]
    );
    console.log('✓ Dual-wrote id', a.id);
    return a;
  }

  // after cutover, single-write to primary (Shard-B)
  const { rows: [u] } = await primary.query(
    `INSERT INTO users (name,email) VALUES ($1,$2) RETURNING id,created_at;`,
    [name, email]
  );
  console.log('✓ Cutover-write id', u.id);
  return u;
}