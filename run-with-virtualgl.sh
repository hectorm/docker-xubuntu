#!/bin/sh

set -eu
export LC_ALL=C

DOCKER=$(command -v docker 2>/dev/null)

IMAGE_REGISTRY=docker.io
IMAGE_NAMESPACE=hectormolinero
IMAGE_PROJECT=xubuntu
IMAGE_TAG=latest
IMAGE_NAME=${IMAGE_REGISTRY:?}/${IMAGE_NAMESPACE:?}/${IMAGE_PROJECT:?}:${IMAGE_TAG:?}
CONTAINER_NAME=${IMAGE_PROJECT:?}

imageExists() { [ -n "$("${DOCKER:?}" images -q "${1:?}")" ]; }
containerExists() { "${DOCKER:?}" ps -af name="${1:?}" --format '{{.Names}}' | grep -Fxq "${1:?}"; }
containerIsRunning() { "${DOCKER:?}" ps -f name="${1:?}" --format '{{.Names}}' | grep -Fxq "${1:?}"; }

if ! imageExists "${IMAGE_NAME:?}" && ! imageExists "${IMAGE_NAME#docker.io/}"; then
	>&2 printf -- '%s\n' "\"${IMAGE_NAME:?}\" image doesn't exist!"
	exit 1
fi

if containerIsRunning "${CONTAINER_NAME:?}"; then
	printf -- '%s\n' "Stopping \"${CONTAINER_NAME:?}\" container..."
	"${DOCKER:?}" stop "${CONTAINER_NAME:?}" >/dev/null
fi

if containerExists "${CONTAINER_NAME:?}"; then
	printf -- '%s\n' "Removing \"${CONTAINER_NAME:?}\" container..."
	"${DOCKER:?}" rm "${CONTAINER_NAME:?}" >/dev/null
fi

printf -- '%s\n' "Creating \"${CONTAINER_NAME:?}\" container..."
"${DOCKER:?}" run --detach \
	--name "${CONTAINER_NAME:?}" \
	--hostname "${CONTAINER_NAME:?}" \
	--restart on-failure:3 \
	--log-opt max-size=32m \
	--publish 3322:3322/tcp \
	--publish 3389:3389/tcp \
	--shm-size 2g \
	--privileged \
	--env ENABLE_SSHD=true \
	--env ENABLE_VIRTUALGL=true \
	"${IMAGE_NAME:?}" "$@" >/dev/null

printf -- '%s\n\n' 'Done!'
exec "${DOCKER:?}" logs -f "${CONTAINER_NAME:?}"
