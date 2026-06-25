# Acme Portal (WEB-01/02/08) — intentionally vulnerable training app, lab only.
FROM python:3.12-slim

# Non-root runtime user.
RUN useradd --create-home --uid 10001 acme
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

USER acme
EXPOSE 8000

# 2 workers is plenty for a single-team lab; gunicorn binds the seed-on-import.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", \
     "--timeout", "60", "app:app"]
