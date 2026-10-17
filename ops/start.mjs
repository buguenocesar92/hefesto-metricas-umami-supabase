import { spawn, spawnSync } from 'node:child_process';
import { databaseUrls } from './urls.mjs';
process.chdir('/app');
Object.assign(process.env, databaseUrls(process.env));
process.env.PATH = '/app/node_modules/.bin:' + process.env.PATH;
// Keep upstream startup order, inserting the default-password guard before HTTP.
for (const file of ['scripts/check-db.js', '/app/hefesto/guard.mjs', 'scripts/update-tracker.js']) {
  const result = spawnSync(process.execPath, [file], { env: process.env, stdio: 'inherit' });
  if (result.status !== 0) process.exit(result.status || 1);
}
const server = spawn(process.execPath, ['server.js'], { env: process.env, stdio: 'inherit' });
for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, () => server.kill(signal));
server.on('error', () => { console.error('No se pudo iniciar el servidor'); process.exit(1); });
server.on('exit', (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
