# Use nginx alpine as base image for lightweight web serving
FROM nginx:alpine

# Set working directory
WORKDIR /usr/share/nginx/html

# Copy the entire project first
COPY . .

# Move the public directory contents to the root and ensure src is at root level
RUN cp -r public/* . && \
    rm -rf public

# Create a custom nginx configuration for better performance
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Proper MIME types for JavaScript modules \
    location ~* \.js$ { \
    add_header Content-Type "application/javascript; charset=utf-8"; \
    expires 1y; \
    add_header Cache-Control "public, immutable"; \
    } \
    \
    # Enable gzip compression for better performance \
    gzip on; \
    gzip_vary on; \
    gzip_min_length 1024; \
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json; \
    \
    # Cache static assets \
    location ~* \.(css|png|jpg|jpeg|gif|ico|svg)$ { \
    expires 1y; \
    add_header Cache-Control "public, immutable"; \
    } \
    \
    # Handle HTML files \
    location ~* \.html$ { \
    expires -1; \
    add_header Cache-Control "no-cache, no-store, must-revalidate"; \
    } \
    \
    # Default location block \
    location / { \
    try_files $uri $uri/ /index.html; \
    } \
    \
    # Security headers \
    add_header X-Frame-Options "SAMEORIGIN" always; \
    add_header X-Content-Type-Options "nosniff" always; \
    add_header X-XSS-Protection "1; mode=block" always; \
    }' > /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"] 