#FROM node:23-alpine
FROM node:18.20-bullseye-slim
EXPOSE 3000
WORKDIR /app
COPY . .
RUN npm install express
CMD ["node", "server.js"]
