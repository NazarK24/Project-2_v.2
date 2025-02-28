# Вибираємо офіційний базовий образ Python
FROM python:3.11-slim

# Додаємо метаінформацію про об
ARG VERSION=unknown
LABEL version=$VERSION

# Встановлюємо робочу директорію всередині конте
WORKDIR /app

# Копіюємо файл requirements.txt і встановлюємо залежн
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код в контейне
COPY . . 

# Відкриваємо порт, на якому буде працювати додаток
EXPOSE 8001

# Запускаємо додаток
CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]
