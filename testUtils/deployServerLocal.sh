set -euo pipefail

display_usage() {
  printf "Usage ./start.sh [OPT] FN_PATH\nOptions are:\n"
  printf "  -h: Show this message\n"
  printf "  -p: Production node environment\n"
  exit 0
}

NODE_ENV='development'
while getopts "ph" OPT; do
  case "$OPT" in
    "p") NODE_ENV='production';;
    "h") display_info;;
    "?") display_info;;
  esac 
done


shift $((OPTIND - 1)) 
if [  $# -le 0 ] 
then 
  display_usage
  exit 1
fi 

HERMES_CONFIG_PATH="$1/hermes.config.json"
FN_NAME=$( cat $HERMES_CONFIG_PATH | python -c "import json,sys;obj=json.load(sys.stdin);print obj['functionName'];")
LANGUAGE=$( cat $HERMES_CONFIG_PATH | python -c "import json,sys;obj=json.load(sys.stdin);print obj['language'];")
FN_BUILDER_DOCKERFILE=$( curl https://raw.githubusercontent.com/hermes-tcc/project-building-base-images/master/$LANGUAGE.Dockerfile )

echo "======== BUILDING DEVELOPMENT IMAGE ========"
docker build  -t hermeshub/watcher-dev-$LANGUAGE:latest \
              --target="development" \
              --build-arg FN_LANGUAGE=$LANGUAGE \
              -f ../watcher.Dockerfile \
              ../
echo ""
echo ""

echo "======== BUILDING FUNCTION ========"
echo "$FN_BUILDER_DOCKERFILE" | \
  docker build  -t tiagonapoli/build-$FN_NAME \
                -f - \
                $1
echo ""
echo ""

echo "======== BUILDING WATCHER ========"
docker build  -t tiagonapoli/watcher-$FN_NAME:latest \
              --target="$NODE_ENV" \
              --build-arg FN_IMAGE=tiagonapoli/build-$FN_NAME \
              --build-arg FN_LANGUAGE=$LANGUAGE \
              ../
echo ""
echo ""


cd ../
SRC_PATH="$(pwd)"
cd testUtils

docker images tiagonapoli/watcher-$FN_NAME:latest
echo ""
echo ""

docker history tiagonapoli/watcher-$FN_NAME:latest
echo ""
echo ""

MOUNT="--mount type=bind,source=$SRC_PATH,target=/app/server"
if [ "$NODE_ENV" == "production" ]; then
  MOUNT=""
fi

docker run -it --rm \
  -p 8888:8888 \
  -e PORT=8888 \
  -e DEBUG=true \
  -e REDIS_CHANNEL=debug-channel \
  --name=$FN_NAME-test-watcher \
  $MOUNT \
  tiagonapoli/watcher-$FN_NAME
