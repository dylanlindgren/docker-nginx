FROM centos:latest

MAINTAINER "Dylan Lindgren" <dylan.lindgren@gmail.com>

# Set home environment variable, as Docker does not look this up in /etc/passwd
ENV HOME /root

# Install trusted CA's (needed in the environment this was developed for)
ADD build/certs /tmp/certs
RUN cat /tmp/certs >> /etc/pki/tls/certs/ca-bundle.crt

# Install required repos and update
ADD build/nginx.repo /etc/yum.repos.d/nginx.repo
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-1.noarch.rpm
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
RUN yum update -y

# Install Nginx
RUN yum install -y nginx

# Apply configuration
ADD build/nginx.conf /etc/nginx/nginx.conf

# DATA VOLUMES
RUN mkdir /data
RUN mkdir /data/www
RUN mkdir /data/nginx
RUN mkdir /data/nginx/sites
RUN mkdir /data/nginx/logs

# Contains the website's www data
VOLUME ["/data/www"]

# Contains the Nginx server's website definitions
VOLUME ["/data/nginx/sites"]

# Contains the log files for Nginx
VOLUME ["/data/nginx/logs"]

# PORTS
# Port 80 for http
EXPOSE 80
# Port 443 for https
EXPOSE 443

# This script gets the linked PHP-FPM container's IP and puts it into
# the upstream definition in the /etc/nginx/nginx.conf file, after which
# it launches Nginx.
ADD build/nginx.sh /opt/bin/nginx.sh
RUN chmod u=rwx /opt/bin/nginx.sh

# Run the Nginx startup script on container start.
ENTRYPOINT ["/opt/bin/nginx.sh"]
