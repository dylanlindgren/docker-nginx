#!/bin/bash

cd /tmp
yum install -y wget tar openssl-devel gcc gcc-c++ make zlib-devel pcre-devel gd-devel krb5-devel git
wget http://nginx.org/download/nginx-1.6.1.tar.gz
tar -xzf nginx-1.6.1.tar.gz
cd /tmp/nginx-1.6.1
git clone https://github.com/stnoonan/spnego-http-auth-nginx-module.git
./configure \
	--user=nginx \
	--with-debug \
	--group=nginx \
	--prefix=/usr/share/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--pid-path=/run/nginx.pid \
	--lock-path=/run/lock/subsys/nginx \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--with-http_gzip_static_module \
	--with-http_stub_status_module \
	--with-http_ssl_module \
	--with-http_spdy_module \
	--with-pcre \
	--with-http_image_filter_module \
	--with-file-aio \
	--with-ipv6 \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--add-module=spnego-http-auth-nginx-module
make
make install
adduser -c "Nginx user" nginx
setcap cap_net_bind_service=ep /usr/sbin/nginx
yum remove -y wget tar openssl-devel gcc gcc-c++ make zlib-devel pcre-devel gd-devel krb5-devel git
