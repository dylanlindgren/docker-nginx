![Docker & Nginx](https://cloud.githubusercontent.com/assets/6241518/4104908/424e46f8-319b-11e4-9a2e-49a8cc49951c.jpg)

docker-nginx is a CentOS-based docker container for [Nginx](http://nginx.org). It is intended for use with [dylanlindgren/docker-phpfpm](https://github.com/dylanlindgren/docker-phpfpm).

## Getting the image
This image is published in the [Docker Hub](https://registry.hub.docker.com/u/dylanlindgren/docker-nginx/). Simply run the below command to get it on your machine:

```bash
docker pull dylanlindgren/docker-nginx
```
## Nginx site config and www data
All site and log data is configured to be located in a Docker volume so that it is persistent and can be shared by other containers (such as php-fpm or a backup container).

There are two volumes defined in this image:

- `/data/nginx/www`
- `/data/nginx/config`

Within these folders this image expects the below directory structure:
```
/data
└────nginx
     ├─── www
     |    ├─── website1_files
     |    |    └  ...
     |    └─── website2_files
     |         └  ...
     └─── config
          ├─── logs
          |    └  ...
          └─── sites
               ├─── available
               |    |  website1
               |    |  website2
               |    └  ...
               └─── enabled
                    |  website1_symlink
                    └  ...
```
[PHP-FPM](https://github.com/dylanlindgren/docker-phpfpm) requires access to the `www` directory in the same location as Nginx has it, so instead of mounting `/data/nginx/www` in this container, we will mount it in the PHP-FPM container and use the `--volumes-from` switch (as due to the `--link` command the PHP-FPM container needs to be run first anyway).

The `available` and `enabled` directories under `/data/nginx/config/sites` both operate in the same fashion as the regular `sites-available` and `sites-enabled` directories in Nginx - that is, put your website config files all in the `available` directory and create symlinks to these files in the `enabled` directory with the below command (after `cd`ing into the `enabled` directory).
```bash
ln -s ../available/website1 website1
```

Each of the files under the `/data/nginx/config/sites/available` directory should contain a definition for a Nginx server. For example:
```
server {
    listen       80;
    server_name  www.website1.com;
    root              /data/www/website1_files/public;

    location ~* \.(html|jpg|jpeg|gif|png|css|js|ico|xml)$ {
        access_log        off;
        log_not_found     off;
        expires           360d;
    }

    location ~* \.php$ {
        include fastcgi.conf;
        fastcgi_pass nginx_backend;
    }
}
```

## Creating and running the container
**NOTE:** a container based on [dylanlindgren/docker-phpfpm](https://github.com/dylanlindgren/docker-phpfpm) must be created before running the below steps. In the below commands, this container is referred to as `phpfpm`.

To create and run the container:
```bash
docker run --privileged=true -p 80:80 -p 443:443 --name nginx -v /data/nginx/config:/data/nginx/config:rw --volumes-from phpfpm --link phpfpm:fpm -d dylanlindgren/docker-nginx
```
 - the first `-p` maps the container's port 80 to port 80 on the host, the second maps the container's 443 to the hosts 443.
 - `--name` sets the name of the container (useful when starting/stopping).
 - `-v` maps the `/data/nginx/config` folder as read/write (rw).
 - `--volumes-from`  gets volumes from the `phpfpm` container (it should have `/data/nginx/www` mapped)
 - `--link` allows this container and the `phpfpm` container to talk to each other over IP.
 - `-d` runs the container as a daemon

To stop the container:
```bash
docker stop nginx
```

To start the container again:
```bash
docker start nginx
```
### Running as a Systemd service
To run this container as a service on a [Systemd](http://www.freedesktop.org/wiki/Software/systemd/) based distro (e.g. CentOS 7), create a unit file under `/etc/systemd/system` called `nginx.service` with the below contents
```bash
[Unit]
Description=Nginx Docker container (dylanlindgren/docker-nginx)
After=docker.service
After=phpfpm.service
Requires=docker.service
Requires=phpfpm.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker stop nginx
ExecStartPre=-/usr/bin/docker rm nginx
ExecStartPre=-/usr/bin/docker pull dylanlindgren/docker-nginx
ExecStart=/usr/bin/docker run --privileged=true -p 80:80 -p 443:443 --name nginx -v /data/nginx/config:/data/nginx/config:rw --volumes-from phpfpm --link phpfpm:fpm dylanlindgren/docker-nginx
ExecStop=/usr/bin/docker stop nginx

[Install]
WantedBy=multi-user.target
```
Then you can start/stop/restart the container with the regular Systemd commands e.g. `systemctl start nginx.service`.

To automatically start the container when you restart enable the unit file with the command `systemctl enable nginx.service`.

Something to note is that this service is set to require `phpfpm.service` which is a service which runs the php-fpm container made with  [dylanlindgren/docker-phpfpm](https://github.com/dylanlindgren/docker-phpfpm).

## Acknowledgements
The below pages were very useful in the creation of both of these projects.

 - [enalean.com](http://www.enalean.com/en/Deploy-%20PHP-app-Docker-Nginx-FPM-CentOSSCL)
 - [stage1.io](http://stage1.io/blog/making-docker-containers-communicate/)
 - [coreos.com](https://coreos.com/docs/launching-containers/launching/getting-started-with-systemd/)
