# Use a lightweight base Python image
FROM python:3.9-alpine3.21

# Set a working directory
WORKDIR /app

# Copy and install dependencies
COPY app/requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the actual application
COPY app /app

# Expose port 83
EXPOSE 8088

# Run the application with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8088"]