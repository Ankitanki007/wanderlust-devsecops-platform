FROM node:22-bookworm-slim AS dependencies

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM gcr.io/distroless/nodejs22-debian13:nonroot AS runtime

ENV NODE_ENV=production
WORKDIR /app

COPY --chown=65532:65532 package.json server.js ./
COPY --chown=65532:65532 config/ ./config/
COPY --chown=65532:65532 controllers/ ./controllers/
COPY --chown=65532:65532 models/ ./models/
COPY --chown=65532:65532 routes/ ./routes/
COPY --chown=65532:65532 services/ ./services/
COPY --chown=65532:65532 utils/ ./utils/
COPY --chown=65532:65532 public/ ./public/
COPY --from=dependencies --chown=65532:65532 /app/node_modules ./node_modules

USER 65532:65532
EXPOSE 8080

CMD ["server.js"]
