FROM node:22-slim AS frontend
WORKDIR /app
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY web/frontend/package.json web/frontend/package-lock.json* ./
RUN npm ci
COPY web/frontend/ ./
RUN npm run build

FROM python:3.12-slim
WORKDIR /app
COPY web/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY web/backend/ ./backend/
COPY --from=frontend /app/dist ./frontend/dist/
EXPOSE 8084
CMD ["gunicorn", "backend.app:app", "--bind", "0.0.0.0:8084", "--workers", "2"]
