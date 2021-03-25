#!/bin/bash

set -e

PACKAGE=introspector
VERSION=${1:-latest}

echo "Building images"
docker/build.sh $PACKAGE $VERSION

echo "Building launcher"
launcher/build.sh

mkdir -p dist

INTROSPECTOR_DOCKER_REPO=${DOCKER_REPO:-goldfig}
IMAGE="${INTROSPECTOR_DOCKER_REPO}/${PACKAGE}"
ESCAPED_IMAGE=$(printf '%s\n' "$IMAGE" | sed -e 's/[\/&]/\\&/g')
sed "s/build: ./image: ${ESCAPED_IMAGE}:${VERSION}/g" docker-compose.yml > dist/docker-compose.yml
cp launcher/dist/* dist/

cd dist
# Build linux package
ln introspector_linux introspector
zip introspector_linux.zip introspector docker-compose.yml
unlink introspector

# Build osx package
ln introspector_osx introspector
zip introspector_osx.zip introspector docker-compose.yml
unlink introspector

# Build m1 osx package
ln introspector_osx_m1 introspector
zip introspector_osx_m1.zip introspector docker-compose.yml
unlink introspector

