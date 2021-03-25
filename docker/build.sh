set -e

PACKAGE=$1
VERSION=$2
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
${DIR}/build_arm.sh $PACKAGE $VERSION
${DIR}/build_amd.sh $PACKAGE $VERSION