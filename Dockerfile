FROM centos:latest

MAINTAINER "Dylan Lindgren" <dylan.lindgren@gmail.com>

# Install trusted CA's (needed in the environment this was developed for)
ADD build/certs /tmp/certs
RUN cat /tmp/certs >> /etc/pki/tls/certs/ca-bundle.crt

# Build Nginx from source with appropriate modules
ADD build/nginx-build.sh /tmp/nginx-build.sh
RUN chmod ugo+x /tmp/nginx-build.sh
WORKDIR /tmp
RUN /tmp/nginx-build.sh
RUN rm -R -f /tmp/*

# Apply Nginx configuration
ADD config/nginx.conf /etc/nginx/nginx.conf

# This script gets the linked PHP-FPM container's IP and puts it into
# the upstream definition in the /etc/nginx/nginx.conf file, after which
# it launches Nginx.
ADD config/nginx.sh /opt/bin/nginx.sh
RUN chmod u=rwx /opt/bin/nginx.sh
RUN chown nginx:nginx /opt/bin/nginx.sh /etc/nginx /etc/nginx/nginx.conf /var/log/nginx /usr/share/nginx

# DATA VOLUMES
RUN mkdir -p /data/nginx/www/
RUN mkdir -p /data/nginx/config/
# Contains the website's www data
VOLUME ["/data/nginx/www"]
# Contains the Nginx server's site definitions and logs
VOLUME ["/data/nginx/config"]

# PORTS
# Port 80 for http
EXPOSE 80
# Port 443 for https
EXPOSE 443

USER nginx

# Run the Nginx startup script on container start.
ENTRYPOINT ["/opt/bin/nginx.sh"]
