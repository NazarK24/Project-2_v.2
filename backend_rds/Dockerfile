# backendrds/Dockerfile

# Use the official Python image from the Docker H
FROM python:3.9

# Set the working directory in the containe
WORKDIR /app

# Copy the requirements file into the conta
COPY requirements.txt /app/

# Install any dependencies
RUN pip install -r requirements.txt

# Copy the current directory contents into the container at /app
COPY . /app/

# Make port 8001 available to the world outside this contain
EXPOSE 8001

# Run the command to start the Django server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]
