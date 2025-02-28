# Вибираємо офіційний базовий образ Python
FROM python:3.11-slim

# Додаємо метаінформацію про образ
ARG VERSION=unknown
LABEL version=$VERSION

# Встановлюємо робочу директорію всередині контейне
WORKDIR /app

# Копіюємо файл requirements.txt і встановлюємо залежнос
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код в контейне
COPY . .

# Відкриваємо порт, на якому буде працюва
EXPOSE 8002

# Запускаємо додаток
CMD ["python", "manage.py", "runserver", "0.0.0.0:8002"]