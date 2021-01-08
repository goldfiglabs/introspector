#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PACKAGE=`basename $DIR`

echo "Building package ${PACKAGE}"

pipenv lock -r > requirements.txt

GOLDFIG_DOCKER_REPO=${DOCKER_REPO:-goldfig}
IMAGE="${GOLDFIG_DOCKER_REPO}/${PACKAGE}"
DOCKER_BUILDKIT=1 docker build -t ${IMAGE} .

echo "Building launcher"
launcher/build.sh

mkdir -p dist

ESCAPED_IMAGE=$(printf '%s\n' "$IMAGE" | sed -e 's/[\/&]/\\&/g')
sed "s/build: ./image: ${ESCAPED_IMAGE}:latest/g" docker-compose.yml > dist/docker-compose.yml
cp launcher/dist/* dist/

cd dist
# Build linux package
ln gf_linux gf
zip goldfig_linux.zip gf docker-compose.yml
unlink gf

# Build osx package
ln gf_osx gf
zip goldfig_osx.zip gf docker-compose.yml
unlink gf

echo "To publish"
echo "docker push ${IMAGE}:latest"