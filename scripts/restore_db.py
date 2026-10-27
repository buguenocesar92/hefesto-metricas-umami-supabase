#!/usr/bin/env python3
"""Restaura solo el esquema public de Umami en un proyecto nuevo y vacio.

Sin --confirmar CONFIRMAR_RESTAURACION no se escribe nada; con --dry-run se
simula. Valida el manifiesto y los sha256 antes de tocar el destino, exige el
esquema public vacio y deja restore-report.json y auditoria.

El .env NO viaja en el respaldo: el destino debe conservar APP_SECRET y
TWO_FACTOR_ENCRYPTION_KEY. El respaldo solo deja los nombres de variable.
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import (RespaldoError, auditar, ejecutar,  # noqa: E402
                               ejecutar_check, escribir_informe, opciones_restore)

SOFTWARE = 'hefesto-metricas'
VERSION = '3.4.0'
DATABASE = 'postgresql'


def dc(*args, **kw):
    return subprocess.run(['docker', 'compose', *args], check=True, **kw)


def main():
    modo, origen = opciones_restore(sys.argv[1:])
    root = Path(__file__).resolve().parents[1]
    os.chdir(root)
    origen = Path(origen).resolve()
    ejecutar_check(str(origen), SOFTWARE, VERSION, DATABASE)
    if modo == 'dry-run':
        print('Simulacion: el respaldo es integro y no se escribio nada.')
        print('Para restaurar de verdad: --confirmar CONFIRMAR_RESTAURACION')
        return 0
    if not (root / '.env').is_file():
        raise RespaldoError('Falta el .env del destino: el .env no viaja en el respaldo', 5)
    for service in ['app']:
        if dc('ps', '--status', 'running', '-q', service,
               capture_output=True, text=True).stdout.strip():
            raise RespaldoError('Detener Umami antes de restaurar en destino nuevo', 5)
    count = dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'psql', 'dbtools',
               '-Atc', "SELECT count(*) FROM pg_tables WHERE schemaname='public'",
               capture_output=True, text=True).stdout.strip()
    if count != '0':
        raise RespaldoError('public no esta vacio; no se sobrescribiran datos', 5)
    dump = origen / 'public.dump'
    with dump.open('rb') as stream:
        toc = dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'pg_restore',
                 'dbtools', '--list', stdin=stream, stdout=subprocess.PIPE).stdout.decode()
    # public ya existe en Supabase: no se dropea ni se restaura su entrada de SCHEMA.
    lines = [line for line in toc.splitlines()
             if not re.match(r'^\d+;\s+\d+\s+\d+\s+SCHEMA\s+-\s+public(?:\s|$)', line)]
    with tempfile.TemporaryDirectory(prefix='hefesto-restore-') as d:
        path = Path(d) / 'restore.list'
        path.write_text('\n'.join(lines) + '\n')
        os.chmod(d, 0o755)
        os.chmod(path, 0o644)
        with dump.open('rb') as stream:
            dc('run', '--rm', '--no-deps', '-T', '-v', d + ':/restore:ro',
               '--entrypoint', 'pg_restore', 'dbtools', '--exit-on-error',
               '--no-owner', '--no-acl', '--use-list=/restore/restore.list',
               '--dbname=postgres', stdin=stream)
    escribir_informe(origen, software=SOFTWARE, version=VERSION, database=DATABASE,
                     modo='confirmado', resultado='restaurado', destino=str(root))
    auditar(root, operacion='restore', kit=SOFTWARE, origen=str(origen),
            destino=str(root), resultado='restaurado')
    print('Base restaurada. Recupere APP_SECRET y TWO_FACTOR_ENCRYPTION_KEY '
          'antes de iniciar Umami.')
    return 0


if __name__ == '__main__':
    raise SystemExit(ejecutar(main))
