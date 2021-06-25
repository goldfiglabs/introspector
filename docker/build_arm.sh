#!/bin/bash

set -e

PACKAGE=$1
VERSION=$2

echo "Building package ${PACKAGE}"

pipenv lock -r > requirements.txt

INTROSPECTOR_DOCKER_REPO=${DOCKER_REPO:-goldfig}
IMAGE="${INTROSPECTOR_DOCKER_REPO}/${PACKAGE}:arm64-${VERSION}"
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile-arm --platform linux/arm64 -t ${IMAGE} .

echo "Built ${IMAGE}"