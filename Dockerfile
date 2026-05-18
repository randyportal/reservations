FROM python:3.9-slim

# Instalar dependencias para PDF y sistema
RUN apt-get update && apt-get install -y \
    wget xz-utils libxrender1 libfontconfig1 libx11-dev \
    libjpeg62-turbo libxext6 fontconfig libssl-dev \
    xfonts-75dpi xfonts-base && rm -rf /var/lib/apt/lists/*

# Instalar wkhtmltopdf
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb \
    && dpkg -i wkhtmltox_0.12.6-1.buster_amd64.deb || apt-get install -f -y \
    && rm wkhtmltox_0.12.6-1.buster_amd64.deb

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install gunicorn whitenoise

COPY . .

ENV PRODUCTION=1
ENV DATABASE_NAME=database.sqlite3
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

# Migrar base de datos, recolectar estáticos y lanzar
CMD python manage.py migrate && \
    python manage.py collectstatic --noinput && \
    gunicorn reservations.wsgi:application --bind 0.0.0.0:8000
