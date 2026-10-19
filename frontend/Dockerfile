FROM node:22-bookworm-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY index.html ./
COPY vite.config.ts tsconfig.json tsconfig.node.json tsconfig.prod.json ./
COPY postcss.config.js tailwind.config.js components.json ./
COPY public/ ./public/
COPY src/ ./src/

ENV VITE_API_PATH=""
RUN npm run build

FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

USER root
RUN apk upgrade --no-cache libexpat
USER nginx

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
