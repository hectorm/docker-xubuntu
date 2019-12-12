# Xubuntu on Docker

A Docker image based on Ubuntu 18.04 with the Xfce desktop environment,
[XRDP](https://github.com/neutrinolabs/xrdp),
[XRDP PulseAudio module](https://github.com/neutrinolabs/pulseaudio-module-xrdp) and
[VirtualGL](https://github.com/VirtualGL/virtualgl).

## Start an instance

```sh
docker run --detach \
  --name xubuntu \
  --publish 3389:3389/tcp \
  --shm-size 2g \
  --device /dev/dri \
  hectormolinero/xubuntu:latest
```

> You will be able to connect to the container via RDP through 3389/tcp port.

> **Important:** some software (like Firefox) need the shared memory to be increased, if you
encounter any problem related to this you may use the `--shm-size` option.

> **Important:** enabling VirtualGL support requires the `--privileged` option and the X server
required for VirtualGL will conflict with the host X server.

## Environment variables

* `UNPRIVILEGED_USER_UID`: unprivileged user UID (`1000` by default).
* `UNPRIVILEGED_USER_GID`: unprivileged user GID (`1000` by default).
* `UNPRIVILEGED_USER_NAME`: unprivileged user name (`guest` by default).
* `UNPRIVILEGED_USER_PASSWORD`: unprivileged user password (`password` by default).
* `UNPRIVILEGED_USER_GROUPS`: unprivileged user groups (`audio,input,video` by default).
* `UNPRIVILEGED_USER_SHELL`: unprivileged user shell (`/bin/bash` by default).
* `ENABLE_SSHD`: enable SSH server in the container (`false` by default).
* `ENABLE_VIRTUALGL`: enable VirtualGL support in the container (`false` by default).

## License

See the [license](LICENSE.md) file.
