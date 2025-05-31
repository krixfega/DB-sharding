import { Pool } from 'pg';
import dotenv from 'dotenv';
dotenv.config();

const confA = {
  host: process.env.DATABASE_HOST,
  port: parseInt(process.env.PORT_A, 10),
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASS,
  database: process.env.DATABASE_NAME,
};
const confB = {
  ...confA,
  port: parseInt(process.env.PORT_B, 10),
};

// Always have both pools for dual-write
export const poolA = new Pool(confA);
export const poolB = new Pool(confB);

// Pick one as “primary” once cutover is done
export const primary = process.env.CUTOVER === 'true'
  ? poolB
  : poolA;