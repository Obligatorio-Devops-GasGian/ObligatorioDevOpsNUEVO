# test_funcional.py
# Verifica que vote/app.py se ejecuta sin errores

import subprocess

def test_app_runs():
    subprocess.run(
        ["python", "vote/app.py"],
        check=True,
        timeout=10
    )
