# Container "<nome-servizio>": API FastAPI sulla porta 8000.
# Build context = radice del repo (serve per copiare eventuali libs/ condivise):
#   docker build -f services/<nome-servizio>/Dockerfile .
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# 1. dipendenze (cambiano di rado: layer separato, cache Docker)
COPY services/<nome-servizio>/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. servizio
COPY services/<nome-servizio>/app/ app/

EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
