FROM python:3.9-slim

# 1. Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git build-essential wget xz-utils libxrender1 libfontconfig1 \
    libx11-dev libjpeg62-turbo libxext6 fontconfig libssl-dev \
    xfonts-75dpi xfonts-base && rm -rf /var/lib/apt/lists/*

# 2. Instalar wkhtmltopdf en el sistema
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb \
    && dpkg -i wkhtmltox_0.12.6-1.buster_amd64.deb || apt-get install -f -y \
    && rm wkhtmltox_0.12.6-1.buster_amd64.deb

WORKDIR /app

# 3. Instalar dependencias de Python
COPY requirements.txt .
RUN sed -i 's/git:\/\/github.com/https:\/\/github.com/g' requirements.txt \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn whitenoise

# 4. Copiar el código del proyecto
COPY . .

# 5. FORZAR LA RUTA QUE PIDE LA APP (./bin/wkhtmltopdf )
# Lo hacemos después de copiar el código para asegurar que la carpeta bin existe y tiene el link
RUN mkdir -p /app/bin && \
    rm -f /app/bin/wkhtmltopdf && \
    ln -s /usr/local/bin/wkhtmltopdf /app/bin/wkhtmltopdf && \
    chmod +x /usr/local/bin/wkhtmltopdf

# 6. Permisos para la base de datos y estáticos
RUN chmod -R 777 /app

ENV PRODUCTION=1
ENV DATABASE_NAME=database.sqlite3
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate && python manage.py collectstatic --noinput && gunicorn reservations.wsgi:application --bind 0.0.0.0:8000"]
