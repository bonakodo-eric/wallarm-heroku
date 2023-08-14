FROM ubuntu:22.04

ENV PORT=3000
ENV WALLARM_LABELS="group=heroku"
ENV WALLARM_API_TOKEN=
ENV WALLARM_API_HOST="us1.api.wallarm.com"

RUN apt-get -y update && apt-get -y install nginx curl && apt-get clean

# Download and unpack the Wallarm meganode without installing
RUN curl -o /install.sh "https://meganode.wallarm.com/4.6/wallarm-4.6.10.x86_64-glibc.sh" \
		&& chmod +x /install.sh \
		&& /install.sh --noexec --target /opt/wallarm \
		&& rm -f /install.sh

# Set tarantool's $PORT variable explicitly as it conflicts with Heroku's $PORT
RUN sed -i '/^\[program:tarantool\]$/a environment=PORT=3313' /opt/wallarm/etc/supervisord.conf
# Run supervisord in background. Our foreground process is the Heroku app itself
RUN sed -i '/nodaemon=true/d' /opt/wallarm/etc/supervisord.conf
# Add nginx to supervisord
RUN printf "\n\n[program:nginx]\ncommand=/usr/sbin/nginx\nautorestart=true\nstartretries=4294967295" | tee -a /opt/wallarm/etc/supervisord.conf

# Heroku runs everything under an unprivileged user (dyno:dyno), so we need to grant it access to Wallarm folders
# TODO consider adduser with specific UID and chown instead?
RUN find /opt/wallarm -type d -exec chmod 777 {} \;

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
# Herokuesque 403 error page
COPY 403.html /usr/share/nginx/html/403.html

# Add entrypoint
COPY entrypoint.sh /entrypoint.sh

# Let entrypoint modify the config under dyno:dyno and redirect nginx logs to console
RUN chmod 666 /etc/nginx/nginx.conf \
		&& chmod 777 /etc/nginx/ \
		&& ln -sf /dev/stdout /var/log/nginx/access.log \
		&& ln -sf /dev/stderr /var/log/nginx/error.log

ENTRYPOINT ["/entrypoint.sh"]