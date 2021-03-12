#!/bin/bash

set -e

PACKAGE=$1

export DOCKER_BUILDKIT=1
WHEEL_TAG=goldfig/tempbuildwheel:latest
docker build --platform linux/arm64 -f docker/BuildWheelDockerFile -t $WHEEL_TAG .

CONTAINER_ID=$(docker run -t -d --rm $WHEEL_TAG)
echo "Container ID $CONTAINER_ID"
WHEEL_FILE=$(docker exec $CONTAINER_ID /usr/local/bin/pip cache list --format abspath)
echo "Wheel file $WHEEL_FILE"
LOCAL_WHEEL=psycopg2_binary-2.8.6-cp39-cp39-linux_aarch64.whl
docker cp $CONTAINER_ID:$WHEEL_FILE $LOCAL_WHEEL
docker stop $CONTAINER_ID

#PACKAGE=`basename $DIR`

echo "Building package ${PACKAGE}"

pipenv lock -r > requirements.tmp
sed '/psycopg2-binary.*/d' requirements.tmp > requirements.txt
rm requirements.tmp

INTROSPECTOR_DOCKER_REPO=${DOCKER_REPO:-goldfig}
IMAGE="${INTROSPECTOR_DOCKER_REPO}/${PACKAGE}:arm64-latest"
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile-arm --platform linux/arm64 -t ${IMAGE} .

echo "Built ${IMAGE}"