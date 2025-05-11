FROM python:3.11-slim
WORKDIR /app

# requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# app code and models
COPY api   /app/api
COPY models /app/models
COPY data /app/data
EXPOSE 8000
CMD ["python", "api/app.py"]
