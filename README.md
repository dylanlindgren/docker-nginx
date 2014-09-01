docker-nginx
================
docker-nginx is a CentOS-based docker container for [Nginx](http://nginx.org). It is intended for use with [dylanlindgren/docker-phpfpm](https://github.com/dylanlindgren/docker-phpfpm).

## Getting the image
### Option A: Pull from the Docker Hub
This image is published in the [Docker Hub](https://registry.hub.docker.com/). Simply run the below command to get it on your machine:

```bash
docker pull dylanlindgren/docker-nginx
```
### Option B: Build from source
First, `cd` into a directory where you store your Docker repos and clone this repo:

```bash
git clone https://github.com/dylanlindgren/docker-nginx.git
```

`cd` into the newly created `docker-nginx` directory and build the image (replacing `[IMAGENAME]` in the below command with anything you want to call the image once it's built eg: *dylan/nginx*):

```bash
docker build -t [IMAGENAME] .
```

## Nginx site config and www data
Generally we want changes to our website data to be persistent, so that when the container is stopped or destroyed our website data and sites don't go with it. To accomplish this, we are going going to use the `-v` switch for `docker run` to mount volumes on the host inside the container. There will be two volumes, one at `/data/www` and another at `/data/nginx`.

The below directory structure must be manually created on the host before running the container.
```
/data
|
└────www
     ├─── website1_files
          | ...
     ├─── website2_files
          | ...
|
└────nginx
     ├─── logs
          | ...
     |
     ├─── sites
          ├─── available
               |  website1
               |  website2
               | ...
          ├─── enabled
               |  website1_symlink
               | ...
```
[PHP-FPM](https://github.com/dylanlindgren/docker-phpfpm) also requires access to the `/data/www` directory, and so instead of mounting that volume in this container, we will use the `--volumes-from` switch as due to the `--link` command the PHP-FPM container needs to be run first.

The `available` and `enabled` directories under `/data/nginx/sites` both operate in the same fashion as the regular `sites-available` and `sites-enabled` directories in Nginx - that is, put your website config files all in the `available` directory and create symlinks to these files in the `enabled` directory with the below command (after `cd`ing into the `enabled` directory).
```bash
ln -s ../available/website1 website1
```

Each of the files under the `/data/nginx/sites/available` directory should contain a definition for a Nginx server.
```
server {
    listen       80;
    server_name  www.website1.com;

    location ~* \.(html|jpg|jpeg|gif|png|css|js|ico|xml)$ {
        root              /data/www/website1_files/public;
        access_log        off;
        log_not_found     off;
        expires           360d;
    }

    location ~* \.php$ {
        root /data/www;
        include fastcgi.conf;
        fastcgi_pass nginx_backend;
    }
}
```

## Creating and running the container
**NOTE:** a container based on [dylanlindgren/docker-phpfpm](https://github.com/dylanlindgren/docker-phpfpm) must be created before running the below steps.

To create and run the container:
```bash
docker run --privileged=true -p 80:80 --name web -v /data/nginx:/data/nginx:rw --volumes-from php --link php:fpm -d dylanlindgren/docker-nginx
```
 - `-p` maps the container's port 80 to port 80 on the host.
 - `--name` sets the name of the container (useful when starting/stopping).
 - `-v` maps the `/data/nginx` folder as read/write (rw).
 - `--volumes-from`  gets volumes from the `php` container (it should have `/data/www` mapped)
 - `--link` allows this container and the `php` container to talk to each other over IP.
 - `-d` runs the container as a daemon

To stop the container:
```bash
docker stop couchpotato
```

To start the container again:
```bash
docker start couchpotato
```
### Running as a Systemd service
To run this container as a service on a [Systemd](http://www.freedesktop.org/wiki/Software/systemd/) based distro (e.g. CentOS 7), create a unit file under `/etc/systemd/system` called `docker-nginx.service` with the below contents
```bash
[Unit]
Description=Nginx docker container
After=php-fpm.service docker.service
Requires=php-fpm.service docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker stop web
ExecStart=/usr/bin/docker start web
ExecStop=/usr/bin/docker stop web

[Install]
WantedBy=multi-user.target
```
Then you can start/stop/restart the container with the regular Systemd commands e.g. `systemctl start nginx.service`.

To automatically start the container when you restart enable the unit file with the command `systemctl enable nginx.service`.

Something to note is that this service is set to require `docker-phpfpm.service` which is a service which runs the php-fpm container made with  [dylanlindgren/docker-phpfpm](https://github.com/dylanlindgren/docker-phpfpm).

## Acknowledgements
The below two blog posts were very useful in the creation of both of these projects.

 - [enalean.com](http://www.enalean.com/en/Deploy-%20PHP-app-Docker-Nginx-FPM-CentOSSCL)
 - [stage1.io](http://stage1.io/blog/making-docker-containers-communicate/)
