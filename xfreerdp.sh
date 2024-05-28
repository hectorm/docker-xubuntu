#!/bin/sh

set -eu
export LC_ALL=C

RDP_HOST=127.0.0.1
RDP_PORT=3389
RDP_DOMAIN=Xorg
RDP_USER=user
RDP_PASSWORD=password

exec xfreerdp3 \
	/v:"${RDP_HOST:?}":"${RDP_PORT:?}" \
	/u:"${RDP_DOMAIN:?}"\\"${RDP_USER:?}" /p:"${RDP_PASSWORD:?}" \
	/log-level:INFO /cert:ignore \
	/rfx /rfx-mode:video /dynamic-resolution \
	/audio-mode:0 /sound:sys:pulse,rate:44100 \
	/microphone:sys:pulse,rate:44100 \
	+clipboard +home-drive \
	-compression -encryption
