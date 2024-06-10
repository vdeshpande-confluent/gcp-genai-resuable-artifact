

FROM python:3.11-slim-buster


# Copy the requirements file
COPY . .
RUN apt-get update && apt-get install gcc python3-dev -y
RUN pip install -r requirements.local.txt


# Expose the port the app runs on
EXPOSE 8080


# Run the application
CMD ["python", "app/main.py"]
