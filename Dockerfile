FROM centos:latest

MAINTAINER "Dylan Lindgren" <dylan.lindgren@gmail.com>

# Set home environment variable, as Docker does not look this up in /etc/passwd
ENV HOME /root

# Install trusted CA's
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

RUN mkdir /data
RUN mkdir /data/www
RUN mkdir /data/nginx
RUN mkdir /data/nginx/sites
RUN mkdir /data/nginx/logs

# Data volumes
VOLUME ["/data/www"]
VOLUME ["/data/nginx/sites"]
VOLUME ["/data/nginx/logs"]

# The startup script for Nginx
ADD build/nginx.sh /opt/bin/nginx.sh
RUN chmod u=rwx /opt/bin/nginx.sh

# Port 80 is where the Nginx server will listen on
EXPOSE 80

# Default entrypoint when using "docker run" command
ENTRYPOINT ["/opt/bin/nginx.sh"]
