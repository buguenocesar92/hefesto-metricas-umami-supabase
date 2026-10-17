#!/usr/bin/env python3
import os,secrets
from pathlib import Path
r=Path(__file__).resolve().parents[1];s=(r/'.env.example').read_text()
for _ in range(3):s=s.replace('GENERAR_CON_SCRIPT',secrets.token_hex(32),1)
try:fd=os.open(r/'.env',os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
except FileExistsError:raise SystemExit('Ya existe .env; no se sobrescribe')
with os.fdopen(fd,'w') as f:f.write(s)
print('.env creado 0600. Configure host/usuario y asigne DB_PASSWORD al rol umami_app.')
