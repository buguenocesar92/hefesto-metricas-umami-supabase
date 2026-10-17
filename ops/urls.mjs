export function databaseUrls(env) {
  const host = env.HEFESTO_DB_HOST || '';
  const user = env.HEFESTO_DB_USER || '';
  const password = env.HEFESTO_DB_PASSWORD || '';
  if (!/^[a-zA-Z0-9.-]+$/.test(host) || !user || !password) throw new Error('Host o credenciales invalidos');
  const url = new URL(`postgresql://${host}:5432/postgres`);
  url.username = encodeURIComponent(user);
  url.password = encodeURIComponent(password);
  url.searchParams.set('schema', 'public');
  url.searchParams.set('sslmode', 'verify-full');
  url.searchParams.set('sslrootcert', '/certs/ca.crt');
  const runtime = url.toString();
  // Migration engine uses Prisma TLS parameters, not node-postgres parameters.
  url.searchParams.delete('sslrootcert');
  url.searchParams.set('sslmode', 'require');
  url.searchParams.set('sslcert', '/certs/ca.crt');
  url.searchParams.set('sslaccept', 'strict');
  url.searchParams.set('connect_timeout', '15');
  return { DATABASE_URL: runtime, DIRECT_DATABASE_URL: url.toString() };
}
