# <nome-servizio>

Una riga su cosa fa e a chi risponde.

## Avvio locale

```bash
pip install -r requirements.txt -r requirements-dev.txt
uvicorn app.main:app --reload
pytest
```

## In CI

Aggiungi il filtro in `.github/workflows/ci.yml` del prodotto:

```yaml
<nome-servizio>: ['services/<nome-servizio>/**', 'libs/py/**']
```
