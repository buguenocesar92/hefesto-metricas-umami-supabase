export function databaseUrls(env) {
  const host = env.HEFESTO_DB_HOST || '';
  const user = env.HEFESTO_DB_USER || '';
  const password = env.HEFESTO_DB_PASSWORD || '';
  const dbName = env.HEFESTO_DB_NAME || env.DB_NAME || 'postgres';
  const sslMode = env.HEFESTO_DB_SSLMODE || env.DB_SSLMODE || 'verify-full';
  if (!/^[a-zA-Z0-9.-]+$/.test(host) || !user || !password) throw new Error('Host o credenciales invalidos');
  const url = new URL(`postgresql://${host}:5432/${encodeURIComponent(dbName)}`);
  url.username = encodeURIComponent(user);
  url.password = encodeURIComponent(password);
  url.searchParams.set('schema', 'public');
  url.searchParams.set('sslmode', sslMode);
  if (sslMode === 'verify-full' || sslMode === 'verify-ca') {
    url.searchParams.set('sslrootcert', env.PGSSLROOTCERT || '/certs/ca.crt');
  }
  const runtime = url.toString();
  // Migration engine uses Prisma TLS parameters, not node-postgres parameters.
  url.searchParams.delete('sslrootcert');
  if (sslMode !== 'disable') {
    url.searchParams.set('sslmode', 'require');
    if (sslMode === 'verify-full' || sslMode === 'verify-ca') {
      url.searchParams.set('sslcert', env.PGSSLROOTCERT || '/certs/ca.crt');
      url.searchParams.set('sslaccept', 'strict');
    }
  } else {
    url.searchParams.set('sslmode', 'disable');
  }
  url.searchParams.set('connect_timeout', '15');
  return { DATABASE_URL: runtime, DIRECT_DATABASE_URL: url.toString() };
}
