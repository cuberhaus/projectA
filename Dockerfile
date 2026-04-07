FROM python:3.12-slim
WORKDIR /app
COPY web/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY web/backend/ ./backend/
COPY web/frontend/dist ./frontend/dist/
EXPOSE 8084
CMD ["gunicorn", "backend.app:app", "--bind", "0.0.0.0:8084", "--workers", "2"]
