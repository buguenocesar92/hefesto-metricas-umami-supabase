import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '/app/generated/prisma/client.js';
import bcrypt from 'bcryptjs';
const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL }, { schema: 'public' });
const db = new PrismaClient({ adapter });
try {
  const users = await db.user.findMany({ where: { deletedAt: null }, select: { password: true } });
  if (!users.length) throw new Error('Falta cuenta inicial; revisar migraciones nativas');
  if (process.env.HEFESTO_BOOTSTRAP !== 'true') {
    for (const user of users) {
      if (await bcrypt.compare('umami', user.password)) {
        throw new Error('Cambie la contraseña inicial usando el bootstrap privado antes de publicar');
      }
    }
  }
  console.log('Comprobacion de cuenta inicial completada');
} catch (error) {
  console.error(error instanceof Error && /^(Falta cuenta|Cambie la)/.test(error.message) ? error.message : 'Fallo al validar cuenta inicial');
  process.exitCode = 1;
} finally { await db.$disconnect(); }
