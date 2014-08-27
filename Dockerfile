FROM centos:latest

MAINTAINER "Dylan Lindgren" <dylan.lindgren@gmail.com>

ENV HOME /root

# install HDY certificates
ADD build/certs/HDY /tmp/HDY
RUN cat /tmp/HDY >> /etc/pki/tls/certs/ca-bundle.crt

ADD build/nginx.repo /etc/yum.repos.d/nginx.repo

RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/beta/7/x86_64/epel-release-7-0.2.noarch.rpm
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

RUN yum update -y
RUN yum install nginx -y

RUN yum --enablerepo=remi install php-fpm -y

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php.ini
#RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini

RUN mkdir /var/www

ADD build/default /etc/nginx/sites-available/default

EXPOSE 80

VOLUME ["/var/www"]

ENTRYPOINT ["/usr/sbin/nginx", "-c", "/etc/nginx/nginx.conf"]
