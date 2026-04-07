FROM node:22-slim AS frontend
WORKDIR /build
COPY web/frontend/package.json web/frontend/package-lock.json ./
RUN npm ci
COPY web/frontend/ ./
RUN npm run build

FROM python:3.12-slim
WORKDIR /app
COPY web/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY web/backend/ ./backend/
COPY --from=frontend /build/dist ./frontend/dist/
EXPOSE 8084
CMD ["uvicorn", "backend.app:app", "--host", "0.0.0.0", "--port", "8084"]
