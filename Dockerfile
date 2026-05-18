FROM python:3.9-slim

# 1. Instalar dependencias del sistema (incluyendo git y build-essential para paquetes Python)
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    wget \
    xz-utils \
    libxrender1 \
    libfontconfig1 \
    libx11-dev \
    libjpeg62-turbo \
    libxext6 \
    fontconfig \
    libssl-dev \
    xfonts-75dpi \
    xfonts-base \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalar wkhtmltopdf (necesario para los reportes PDF)
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb \
    && dpkg -i wkhtmltox_0.12.6-1.buster_amd64.deb || apt-get install -f -y \
    && rm wkhtmltox_0.12.6-1.buster_amd64.deb

WORKDIR /app

# 3. Copiar requerimientos y corregir el protocolo git:// a https:// automáticamente
COPY requirements.txt .
RUN sed -i 's/git:\/\/github.com/https:\/\/github.com/g' requirements.txt \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn whitenoise

# 4. Copiar el resto del código
COPY . .

# 5. Variables de entorno
ENV PRODUCTION=1
ENV DATABASE_NAME=database.sqlite3
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

# 6. Comando de inicio (Formato JSON para evitar advertencias )
CMD ["sh", "-c", "python manage.py migrate && python manage.py collectstatic --noinput && gunicorn reservations.wsgi:application --bind 0.0.0.0:8000"]
