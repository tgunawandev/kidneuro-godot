# =============================================================================
# KidNeuro Games - Nginx serving Godot HTML5 exports
# =============================================================================
FROM nginx:1.27-alpine

LABEL maintainer="tgunawan <tgunawan@kidneuro.app>" \
      org.opencontainers.image.source="https://github.com/tgunawandev/kidneuro-godot"

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/games.conf /etc/nginx/conf.d/games.conf

# Copy Godot HTML5 exports
COPY games/ /usr/share/nginx/html/games/

# Health check endpoint
RUN echo '{"status":"ok"}' > /usr/share/nginx/html/health

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
