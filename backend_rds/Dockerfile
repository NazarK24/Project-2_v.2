# Вибираємо офіційний базовий образ Python
FROM python:3.9-slim

# Встановлюємо робочу директорію всередині конте
WORKDIR /app

# Копіюємо файл requirements.txt і встановлюємо залежн
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код в контейне
COPY . . 

# Відкриваємо порт, на якому буде працювати додаток
EXPOSE 8001

# Запускаємо додаток
CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]
