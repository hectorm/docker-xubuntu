# Xubuntu on Docker

A Docker image based on Ubuntu 18.04 with Xfce desktop environment,
[VirtualGL](https://github.com/VirtualGL/virtualgl),
[XRDP](https://github.com/neutrinolabs/xrdp) and
[XRDP PulseAudio module](https://github.com/neutrinolabs/pulseaudio-module-xrdp).

## Start an instance

```sh
docker run --detach \
  --name xubuntu \
  --publish 3389:3389/tcp \
  hectormolinero/xubuntu:latest
```

> You will be able to connect to the container via RDP through 3389/tcp port.

> **Important:** if you use the `--privileged` option the container will be able to use the GPU with
VirtualGL, but this will conflict with the host X server.

> **Important:** some software (like Firefox) need the shared memory to be increased, if you
encounter any problem related to this you may use the `--shm-size` option.

## Environment variables

* `GUEST_USER_PASSWORD`: guest user password (`guest` by default).
