"""<nome-servizio>: una riga su cosa fa."""

from fastapi import FastAPI

app = FastAPI(title="<nome-servizio>")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
