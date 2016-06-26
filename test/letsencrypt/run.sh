#! /bin/sh

CONTAINER_NAME=example-haproxy

docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

mkdir -p /tmp/docker-logs/haproxy

# use --net=host to have the same network as the host
sudo docker run \
    --net=host \
    -e CERTS=example.com \
    -e EMAIL=admin@example.com \
    --publish=8888:8888 \
    --publish=80:80 \
    --name ${CONTAINER_NAME} \
    -v ${SCRIPTPATH}/cert-volume:/etc/letsencrypt \
    -v ${SCRIPTPATH}/config.d/:/etc/haproxy.d \
    -v /tmp/docker-logs/haproxy:/var/log \
    --tty \
    --rm \
    tri-bao/haproxy-letsencrypt:1.6.5

