FROM node:20-alpine

WORKDIR /app

# Install system dependencies for pdf-parse and swisseph
RUN apk add --no-cache python3 make g++ poppler-utils

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Create directories
RUN mkdir -p uploads ephe logs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget -q --spider http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
