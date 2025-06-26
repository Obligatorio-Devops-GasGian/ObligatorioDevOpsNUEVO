# test_funcional.py
# Verifica que la app de vote responde correctamente en su ruta raíz

from vote.app import app

def test_app_runs():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200