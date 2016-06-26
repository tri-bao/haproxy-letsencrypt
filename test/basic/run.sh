#! /bin/sh

CONTAINER_NAME=example-haproxy

docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

mkdir -p /tmp/docker-logs/haproxy

# without SSL
sudo docker run \
    --publish=8888:8888 \
    --publish=80:80 \
    --name ${CONTAINER_NAME} \
    -v /tmp/docker-logs/haproxy:/var/log \
    -v ${SCRIPTPATH}/config.d/:/etc/haproxy.d \
    --tty \
    --rm \
    tri-bao/haproxy-letsencrypt:1.6.5

