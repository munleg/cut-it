# Copyright (c) 2026 Cut-it contributors. SPDX-License-Identifier: GPL-3.0-or-later
"""Resolve native PE imports without copying Windows system libraries."""
import pathlib, re, shutil, subprocess, sys
stage = pathlib.Path(sys.argv[1]).resolve()
prefix = pathlib.Path(sys.argv[2]).resolve()
runtime = stage / 'runtime'
available = {p.name.lower(): p for p in (prefix / 'bin').glob('*.dll')}
system = {p.name.lower() for p in pathlib.Path('C:/Windows/System32').glob('*.dll')}
pending = list(stage.rglob('*.dll')) + list(stage.rglob('*.exe'))
seen, copied, missing = set(), set(), set()
while pending:
    path = pending.pop()
    if path in seen:
        continue
    seen.add(path)
    output = subprocess.check_output([str(prefix / 'bin/objdump.exe'), '-p', str(path)], text=True, errors='replace')
    for name in re.findall(r'DLL Name:\s*(\S+)', output):
        key = name.lower()
        if key.startswith(('api-ms-', 'ext-ms-')) or key in system:
            continue
        existing = next((p for p in runtime.glob('*.dll') if p.name.lower() == key), None)
        if existing:
            pending.append(existing)
        elif key in available:
            target = runtime / available[key].name
            shutil.copy2(available[key], target)
            copied.add(available[key].name)
            pending.append(target)
        else:
            missing.add((path.name, name))
print(f'Inspected {len(seen)} binaries; copied {len(copied)} dependencies')
for item in sorted(missing):
    print('UNRESOLVED:', *item)
sys.exit(bool(missing))
