FROM centos:latest

MAINTAINER "Dylan Lindgren" <dylan.lindgren@gmail.com>

# Set home environment variable, as Docker does not look this up in /etc/passwd
ENV HOME /root

# Install certificates
ADD build/certs /tmp/certs
RUN cat /tmp/certs >> /etc/pki/tls/certs/ca-bundle.crt

# Install required repos and update
ADD build/nginx.repo /etc/yum.repos.d/nginx.repo
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/epel-release-7-0.2.noarch.rpm
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
RUN yum update -y

# Install Nginx
RUN yum install -y nginx

# Install PHP-FPM
RUN yum --enablerepo=remi install -y php-cli php-fpm php-mysqlnd php-mssql php-pgsql php-gd php-mcrypt php-ldap php-imap

# Configure PHP to UTC timezone
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php.ini

# Stop Nginx & PHP-FPM from becoming a daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini

RUN mkdir /data
RUN mkdir /data/www
RUN mkdir /data/nginx
RUN mkdir /data/nginx/sites-available
RUN mkdir /data/nginx/sites-enabled
RUN mkdir /data/nginx/logs

ADD build/sites-available/default /data/nginx/sites-available/default

# Data volumes
VOLUME ["/data/www"]
VOLUME ["/data/nginx"]

# Port 80 is where the Nginx server will listen on
EXPOSE 80

# Default entrypoint when using "docker run" command
ENTRYPOINT ["/usr/sbin/nginx", "-c", "/etc/nginx/nginx.conf"]
