# haproxy-letsencrypt
HAProxy with ACME domain validation plugin

Features:

* HAProxy 1.6.5 with the DNS resolution error [patched](http://discourse.haproxy.org/t/dynamic-dns-resolution-does-not-work-for-me-after-1-6-4-to-1-6-5-upgrade/310/2)
* Support splitting configuration into multiple files
* Writing logs to file via rsyslog and rotating log files
* Generating Let's Encrypt certificates via the [ACME domain validation plugin](https://github.com/janeczku/haproxy-acme-validation-plugin)
* Automatically renewing all certificates (once a week)

# Usage

## Preparation
* Make sure your DNS points to your server
* Decide folders storing the following:
    * Configuration: This is mandatory as the image was built without any default configuration file
    * Let's Encrypt's certificates: If you don't specify a folder in your host machine, they will be stored in a container volume.
      When the container stop, all files will not be deleted but not accessible when you start a new container instance.
    * Log files. The same note as Let's Encrypt's certificates
* Prepare configuration for your HAProxy. You can make one big file or split your configuration into multiple files
  (Note that, files are sorted by file names before giving them to HAProxy). See example in test/letsencrypt folder.
  Config files have to be named with .cfg suffix. Otherwise, they will not be picked up by the startup script.
* Make a little shell script to run the container as in the following suggestion:

```
#! /bin/sh
CONFIG_DIR=/etc/haproxy
CERT_DIR=/etc/letsencrypt
LOG_DIR=/var/log/haproxy

sudo mkdir -p ${LOG_DIR}
sudo mkdir -p ${CONFIG_DIR}
sudo mkdir -p ${CERT_DIR}

CONTAINER_NAME=haproxy

# Uncomment this if you want stop the running container anyway.
# docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

PORT_PROXY_STATUS=8888

# In this example, I use --net=host to simply have the same network as the host
# In your production environment, you may use other kind of networks
sudo docker run \
    --net=host \
    -e CERTS=<your domain, ex: example.com> \
    -e EMAIL=<your mail, ex: adin@example.com> \
    --publish=80:80 \
    --publish=443:443 \
    --publish=${PORT_PROXY_STATUS}:${PORT_PROXY_STATUS} \
    <publish more ports, depends on your usage> \
    --name haproxy \
    -v ${CERT_DIR}:/etc/letsencrypt \
    -v ${CONFIG_DIR}:/etc/haproxy.d \
    -v ${LOG_DIR}:/var/log \
    --tty \
    --rm \
    baoho/haproxy-letsencrypt:1.6.5
```

## Generate a new certificate
* Disable configuration for HTTPS frontend. If you put it in a separate file, 
  simply just change its .cfg extension to another name. Without doing this,
  HAProxy will fail to start as the certificate doesn't exist
* Run the script above to start the container
* Run the /certs.sh scripts inside the container by:

```
docker exec -it haproxy /certs.sh staging
```

It's recommended that you test against the Let's Encrypt's staging environment first
(That's why there is the 'staging' argument in the commandline above). By removing the
'staging' argument, you will be generating the real Let's Encrypt certificate.

## Run with the generated certificate
* After the certificate is generated successfully, stop the container:

```
docker stop haproxy
```

* Enable the HTTPS configuration (If you put it in a separate file, just rename its extension back to .cfg)

* Run the script above to start the container again.

# Reload configuration with zero downtime

```
docker kill -s HUP haproxy
```

or when you are inside the container

```
pkill -HUP haproxy
```

# Build this image

```
docker build --rm=true -t baoho/haproxy-letsencrypt:1.6.5 .
```

# Push the image to Docker Hub

```
docker login
docker push baoho/haproxy-letsencrypt:1.6.5
```
