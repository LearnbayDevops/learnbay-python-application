# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file if you have one (you can create one as shown below)
COPY requirements.txt .

# Install Flask and any other dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask app code into the container
COPY app.py .

# Expose the port the app runs on
EXPOSE 5000

# Command to run the Flask app
CMD ["python", "app.py"]
