#!/usr/bin/env python3
"""Respaldo del kit hefesto-metricas (Umami + PostgreSQL).

El .env nunca se copia en claro: al respaldo solo van sus nombres (env.vars) y,
si hay receptor age, el .env cifrado (env.age). El manifiesto lleva las cinco
claves del contrato. Ver docs/CONTRATO-RESPALDO.md.

Ojo: TWO_FACTOR_ENCRYPTION_KEY vive en el .env. Si se pierde, los 2FA
existentes quedan inaccesibles y hay que regenerarlos.
"""
import datetime
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import (escribir_manifiesto, ejecutar,  # noqa: E402
                               exportar_env, marcar_fallido)

SOFTWARE = 'hefesto-metricas'
VERSION = '3.4.0'
DATABASE = 'postgresql'
CONFIG = ['compose.yaml']


def dc(*args, **kw):
    return subprocess.run(['docker', 'compose', *args], check=True, **kw)


def main():
    root = Path(__file__).resolve().parents[1]
    os.chdir(root)
    os.umask(0o077)
    if not (root / '.env').is_file():
        raise SystemExit('Falta .env')
    running = bool(dc('ps', '--status', 'running', '-q', 'app',
                      capture_output=True, text=True).stdout.strip())
    p = root / 'backups' / datetime.datetime.now(datetime.timezone.utc).strftime(
        '%Y%m%dT%H%M%S%fZ')
    p.mkdir(parents=True, mode=0o700)
    try:
        dc('stop', 'app')
        with (p / 'public.dump').open('wb') as f:
            dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'pg_dump', 'dbtools',
               '--format=custom', '--schema=public', '--no-owner', '--no-acl', stdout=f)
        for n in CONFIG:
            shutil.copy2(root / n, p / n)
        meta = exportar_env(root, p)
        escribir_manifiesto(p, SOFTWARE, VERSION, DATABASE, extra=meta)
    except BaseException:
        marcar_fallido(p, SOFTWARE, VERSION, DATABASE)
        raise
    finally:
        if running:
            dc('start', 'app')
    print('Respaldo completo:', p)
    print('El .env no viaja en claro: solo env.vars y, si hay receptor age, env.age.')
    print('APP_SECRET y TWO_FACTOR_ENCRYPTION_KEY se custodian aparte: '
          'sin ellos los 2FA quedan inaccesibles.')
    return 0


if __name__ == '__main__':
    raise SystemExit(ejecutar(main))
