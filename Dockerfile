FROM node:lts-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Expose port 5173 (Vite default port)
EXPOSE 4173

# Start the application
CMD ["npm", "run", "preview","--", "--host", "0.0.0.0", "--port", "4173"]