# Use an official lightweight Python image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy app files into container
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

# Expose Flask port
EXPOSE 5000

# Run the Flask app
#CMD ["python", "app.py"]

# Run Flask app using Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
