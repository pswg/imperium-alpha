import os
import os.path

SQL_COPYRIGHT_NOTICE = """
-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
""".strip()

# 1.2 - codex_sagatus.sql
def generate_codex_sagatus():
  print("Generating '1.2 - codex_sagatus.sql' ... ", end='', flush=True)
  with open('Part 1 - Creation\\1.1 - rhapsodia_vacui.sql') as f:
    content = f.readlines()

  with open('Part 1 - Creation\\1.2 - codex_sagatus.sql', 'w') as f:
    print(SQL_COPYRIGHT_NOTICE, file=f)
    print('', file=f)

    print('ALTER PROCEDURE [Sacrum].[CodexSagatus]', file=f)
    print('  WITH EXECUTE AS OWNER', file=f)
    print('AS', file=f)
    print('BEGIN', file=f)
    for line in content:
      line = line.replace("'", "''").rstrip()
      if not line.startswith('--'):
        print("  PRINT '" + line + "';", file=f)
    print('END', file=f)

  print("Done.")

generate_codex_sagatus()
