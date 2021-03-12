set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
${DIR}/build_arm.sh introspector
${DIR}/build_amd.sh introspector