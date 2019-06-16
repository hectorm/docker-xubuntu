#!/bin/sh

set -eu
export LC_ALL=C

IMAGE_NAMESPACE=hectormolinero
IMAGE_PROJECT=xubuntu
IMAGE_TAG=latest
IMAGE_NAME=${IMAGE_NAMESPACE}/${IMAGE_PROJECT}:${IMAGE_TAG}
CONTAINER_NAME=${IMAGE_PROJECT}

imageExists() { [ -n "$(docker images -q "$1")" ]; }
containerExists() { docker ps -aqf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }
containerIsRunning() { docker ps -qf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }

if ! imageExists "${IMAGE_NAME}"; then
	>&2 printf -- '%s\n' "\"${IMAGE_NAME}\" image doesn't exist!"
	exit 1
fi

if containerIsRunning "${CONTAINER_NAME}"; then
	printf -- '%s\n' "Stopping \"${CONTAINER_NAME}\" container..."
	docker stop "${CONTAINER_NAME}" >/dev/null
fi

if containerExists "${CONTAINER_NAME}"; then
	printf -- '%s\n' "Removing \"${CONTAINER_NAME}\" container..."
	docker rm "${CONTAINER_NAME}" >/dev/null
fi

printf -- '%s\n' "Creating \"${CONTAINER_NAME}\" container..."
docker run --detach \
	--name "${CONTAINER_NAME}" \
	--hostname "${CONTAINER_NAME}" \
	--restart on-failure:3 \
	--log-opt max-size=32m \
	--publish 0.0.0.0:3322:3322/tcp \
	--publish 0.0.0.0:3389:3389/tcp \
	--privileged \
	--shm-size 2g \
	"${IMAGE_NAME}" "$@" >/dev/null

printf -- '%s\n\n' 'Done!'
exec docker logs -f "${CONTAINER_NAME}"
