import { createUser } from './userService.js';

async function main() {
  try {
    await createUser('TestUser', `krixfega+${Date.now()}@gmail.com`);
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

main();