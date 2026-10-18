FROM node:22-bookworm-slim AS dependencies

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM gcr.io/distroless/nodejs22-debian13:nonroot AS runtime

ENV NODE_ENV=production
WORKDIR /app

COPY --chown=65532:65532 . .
COPY --from=dependencies --chown=65532:65532 /app/node_modules ./node_modules

USER 65532:65532
EXPOSE 8080

CMD ["server.js"]
