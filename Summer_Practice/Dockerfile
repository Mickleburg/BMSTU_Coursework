FROM node:16 AS builder

# 1. Установка зависимостей
WORKDIR /app
COPY package*.json ./
RUN npm install -g gulp && \
    npm install

# 2. Копирование и сборка фронтенда
COPY frontend ./frontend
COPY gulpfile.js ./
WORKDIR /app/frontend
ENV DOCKER_BUILD=true
RUN gulp build && \
    ls -la dist/  # Проверка наличия собранных файлов

# 3. Финальный образ с Nginx
FROM nginx:alpine
RUN mkdir -p /usr/share/nginx/html
COPY --from=builder /app/frontend/dist /usr/share/nginx/html
# Кладем конфиг nginx с прокси на backend
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf