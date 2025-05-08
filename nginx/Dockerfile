FROM nginx:mainline-alpine

# Add security headers
RUN apk add --no-cache openssl curl

# Add security hardening
RUN rm /etc/nginx/conf.d/default.conf && \
    sed -i 's/user  nginx;/user  nginx;\nworker_processes auto;\npid \/var\/run\/nginx.pid;/g' /etc/nginx/nginx.conf

# Install entrypoint script for dynamic configurations
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
