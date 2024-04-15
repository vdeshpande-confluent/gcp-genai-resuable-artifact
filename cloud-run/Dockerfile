FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11

# Install dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir -r  requirements.txt

# Copy the app code to the container.
WORKDIR /app
COPY . .

EXPOSE 8080

# Run the app.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]