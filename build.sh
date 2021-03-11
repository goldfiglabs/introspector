#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PACKAGE=`basename $DIR`

echo "Building package ${PACKAGE}"

pipenv lock -r > requirements.txt

INTROSPECTOR_DOCKER_REPO=${DOCKER_REPO:-goldfig}
IMAGE="${INTROSPECTOR_DOCKER_REPO}/${PACKAGE}"
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t ${IMAGE} .

echo "Building launcher"
launcher/build.sh

mkdir -p dist

ESCAPED_IMAGE=$(printf '%s\n' "$IMAGE" | sed -e 's/[\/&]/\\&/g')
sed "s/build: ./image: ${ESCAPED_IMAGE}:latest/g" docker-compose.yml > dist/docker-compose.yml
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

echo "To publish"
echo "docker push ${IMAGE}:latest"