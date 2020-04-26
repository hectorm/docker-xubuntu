m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:18.04]], [[FROM docker.io/ubuntu:18.04]]) AS build
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& sed -i 's/^#\s*\(deb-src\s\)/\1/g' /etc/apt/sources.list \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
	&& dpkg --add-architecture i386 \
]])m4_dnl
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bison \
		build-essential \
		ca-certificates \
		checkinstall \
		cmake \
		flex \
		git \
		intltool \
		libegl1-mesa-dev \
		libepoxy-dev \
		libfdk-aac-dev \
		libfuse-dev \
		libgbm-dev \
		libgl1-mesa-dev \
		libglu1-mesa-dev \
		libmp3lame-dev \
		libopus-dev \
		libpam0g-dev \
		libpixman-1-dev \
		libpulse-dev \
		libssl-dev \
		libsystemd-dev \
		libtool \
		libx11-dev \
		libx11-xcb-dev \
		libxcb-glx0-dev \
		libxcb-keysyms1-dev \
		libxcb1-dev \
		libxext-dev \
		libxfixes-dev \
		libxml2-dev \
		libxrandr-dev \
		libxtst-dev \
		libxv-dev \
		nasm \
		ocl-icd-opencl-dev \
		pkg-config \
		texinfo \
		xserver-xorg-dev-hwe-18.04 \
		xsltproc \
		xutils-dev \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
		g++-multilib \
		libegl1-mesa-dev:i386 \
		libgl1-mesa-dev:i386 \
		libglu1-mesa-dev:i386 \
		libxtst-dev:i386 \
		libxv-dev:i386 \
		ocl-icd-opencl-dev:i386 \
]])m4_dnl
	&& rm -rf /var/lib/apt/lists/*

# Build libjpeg-turbo
ARG LIBJPEG_TURBO_TREEISH=2.0.4
ARG LIBJPEG_TURBO_REMOTE=https://github.com/libjpeg-turbo/libjpeg-turbo.git
RUN mkdir /tmp/libjpeg-turbo/
WORKDIR /tmp/libjpeg-turbo/
RUN git clone "${LIBJPEG_TURBO_REMOTE:?}" ./
RUN git checkout "${LIBJPEG_TURBO_TREEISH:?}"
RUN git submodule update --init --recursive
RUN mkdir /tmp/libjpeg-turbo/build/
WORKDIR /tmp/libjpeg-turbo/build/
RUN cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=libjpeg-turbo \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/libjpeg-turbo \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./libjpeg-turbo_*.deb
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
RUN mkdir /tmp/libjpeg-turbo/build32/
WORKDIR /tmp/libjpeg-turbo/build32/
RUN CFLAGS='-m32' CXXFLAGS='-m32' LDFLAGS='-m32' \
	cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=libjpeg-turbo \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/libjpeg-turbo \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./libjpeg-turbo32_*.deb
]])m4_dnl

# Build VirtualGL
ARG VIRTUALGL_TREEISH=2.6.3
ARG VIRTUALGL_REMOTE=https://github.com/VirtualGL/virtualgl.git
RUN mkdir /tmp/virtualgl/
WORKDIR /tmp/virtualgl/
RUN git clone "${VIRTUALGL_REMOTE:?}" ./
RUN git checkout "${VIRTUALGL_TREEISH:?}"
RUN git submodule update --init --recursive
RUN mkdir /tmp/virtualgl/build/
WORKDIR /tmp/virtualgl/build/
RUN sed -i "s|@DEBARCH@|$(dpkg-architecture -qDEB_HOST_ARCH)|g" ../release/deb-control.in
RUN cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=virtualgl \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/VirtualGL \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./virtualgl_*.deb
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
RUN mkdir /tmp/virtualgl/build32/
WORKDIR /tmp/virtualgl/build32/
RUN CFLAGS='-m32' CXXFLAGS='-m32' LDFLAGS='-m32' \
	cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=virtualgl \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/VirtualGL \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./virtualgl32_*.deb
]])m4_dnl

# Build XRDP
ARG XRDP_TREEISH=v0.9.13
ARG XRDP_REMOTE=https://github.com/neutrinolabs/xrdp.git
RUN mkdir /tmp/xrdp/
WORKDIR /tmp/xrdp/
RUN git clone "${XRDP_REMOTE:?}" ./
RUN git checkout "${XRDP_TREEISH:?}"
RUN git submodule update --init --recursive
RUN ./bootstrap
RUN ./configure \
		--prefix=/usr \
		--enable-vsock \
		--enable-tjpeg \
		--enable-fuse \
		--enable-fdkaac \
		--enable-opus \
		--enable-mp3lame \
		--enable-pixman
RUN make -j"$(nproc)"
RUN checkinstall --default --pkgname=xrdp --pkgversion=999 --pkgrelease=0

# Build xorgxrdp
ARG XORGXRDP_TREEISH=v0.2.13
ARG XORGXRDP_REMOTE=https://github.com/neutrinolabs/xorgxrdp.git
RUN mkdir /tmp/xorgxrdp/
WORKDIR /tmp/xorgxrdp/
RUN git clone "${XORGXRDP_REMOTE:?}" ./
RUN git checkout "${XORGXRDP_TREEISH:?}"
RUN git submodule update --init --recursive
RUN ./bootstrap
RUN ./configure --enable-glamor
RUN make -j"$(nproc)"
RUN checkinstall --default --pkgname=xorgxrdp --pkgversion=999 --pkgrelease=0

# Build XRDP PulseAudio module
ARG XRDP_PULSEAUDIO_TREEISH=v0.4
ARG XRDP_PULSEAUDIO_REMOTE=https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/
RUN apt-get update
RUN apt-get build-dep -y pulseaudio
RUN apt-get source pulseaudio && mv ./pulseaudio-*/ ./pulseaudio/
WORKDIR /tmp/pulseaudio/
RUN ./configure
RUN mkdir /tmp/xrdp-pulseaudio/
WORKDIR /tmp/xrdp-pulseaudio/
RUN git clone "${XRDP_PULSEAUDIO_REMOTE:?}" ./
RUN git checkout "${XRDP_PULSEAUDIO_TREEISH:?}"
RUN git submodule update --init --recursive
RUN ./bootstrap
RUN ./configure PULSE_DIR=/tmp/pulseaudio/
RUN make -j"$(nproc)"
RUN checkinstall --default --pkgname=xrdp-pulseaudio --pkgversion=999 --pkgrelease=0

##################################################
## "xubuntu" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:18.04]], [[FROM docker.io/ubuntu:18.04]]) AS xubuntu
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
	&& dpkg --add-architecture i386 \
]])m4_dnl
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		at-spi2-core \
		ca-certificates \
		dbus \
		dbus-x11 \
		libegl1 \
		libepoxy0 \
		libfdk-aac1 \
		libfuse2 \
		libgbm1 \
		libgl1 \
		libgl1-mesa-dri \
		libgl1-mesa-glx \
		libglu1 \
		libmp3lame0 \
		libopus0 \
		libpam0g \
		libpixman-1-0 \
		libpulse0 \
		libssl1.1 \
		libsystemd0 \
		libx11-6 \
		libx11-xcb1 \
		libxcb-glx0 \
		libxcb-keysyms1 \
		libxcb1 \
		libxext6 \
		libxfixes3 \
		libxml2 \
		libxrandr2 \
		libxtst6 \
		libxv1 \
		locales \
		mesa-opencl-icd \
		mesa-va-drivers \
		mesa-vdpau-drivers \
		mesa-vulkan-drivers \
		ocl-icd-libopencl1 \
		openssh-server \
		openssl \
		policykit-1 \
		pulseaudio \
		pulseaudio-utils \
		runit \
		tzdata \
		vulkan-utils \
		xserver-xorg-core-hwe-18.04 \
		xserver-xorg-input-all-hwe-18.04 \
		xserver-xorg-input-evdev-hwe-18.04 \
		xserver-xorg-input-joystick-hwe-18.04 \
		xserver-xorg-video-all-hwe-18.04 \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
		libegl1:i386 \
		libgl1:i386 \
		libgl1-mesa-dri:i386 \
		libgl1-mesa-glx:i386 \
		libglu1:i386 \
		libxtst6:i386 \
		libxv1:i386 \
		mesa-opencl-icd:i386 \
		mesa-va-drivers:i386 \
		mesa-vdpau-drivers:i386 \
		mesa-vulkan-drivers:i386 \
		ocl-icd-libopencl1:i386 \
]])m4_dnl
		adwaita-qt \
		apt-transport-https \
		apt-utils \
		bash \
		bash-completion \
		binutils \
		clinfo \
		curl \
		desktop-file-utils \
		dialog \
		engrampa \
		exo-utils \
		file \
		firefox \
		fonts-dejavu \
		fonts-liberation \
		fonts-noto \
		fonts-noto-color-emoji \
		fonts-ubuntu \
		fuse \
		git \
		gnome-keyring \
		gnupg \
		gtk2-engines-pixbuf \
		htop \
		indicator-application \
		indicator-messages \
		iproute2 \
		iputils-ping \
		libavcodec-extra \
		libcanberra-gtk-module \
		libcanberra-gtk3-module \
		libgtk-3-bin \
		lsof \
		lsscsi \
		menu \
		menu-xdg \
		menulibre \
		mesa-utils \
		mesa-utils-extra \
		mime-support \
		mousepad \
		mugshot \
		nano \
		net-tools \
		netcat-openbsd \
		openjdk-8-jre \
		parole \
		pavucontrol \
		pciutils \
		procps \
		psmisc \
		ristretto \
		sudo \
		thunar-archive-plugin \
		tumbler \
		unzip \
		usbutils \
		wget \
		xauth \
		xdg-user-dirs \
		xdg-utils \
		xfce4 \
		xfce4-indicator-plugin \
		xfce4-notifyd \
		xfce4-pulseaudio-plugin \
		xfce4-screenshooter \
		xfce4-statusnotifier-plugin \
		xfce4-taskmanager \
		xfce4-terminal \
		xfce4-whiskermenu-plugin \
		xfonts-base \
		xfpanel-switch \
		xinput \
		xubuntu-default-settings \
		xutils \
		xz-utils \
		zenity \
		zip \
	&& rm -rf /var/lib/apt/lists/*

# Copy Tini build
m4_define([[TINI_IMAGE_TAG]], m4_ifdef([[CROSS_ARCH]], [[latest-CROSS_ARCH]], [[latest]]))m4_dnl
COPY --from=docker.io/hectormolinero/tini:TINI_IMAGE_TAG --chown=root:root /usr/bin/tini /usr/bin/tini

# Install libjpeg-turbo from package
COPY --from=build --chown=root:root /tmp/libjpeg-turbo/build/libjpeg-turbo_*.deb /tmp/libjpeg-turbo.deb
RUN dpkg -i /tmp/libjpeg-turbo.deb && rm -f /tmp/libjpeg-turbo.deb
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
COPY --from=build --chown=root:root /tmp/libjpeg-turbo/build32/libjpeg-turbo32_*.deb /tmp/libjpeg-turbo32.deb
RUN dpkg -i /tmp/libjpeg-turbo32.deb && rm -f /tmp/libjpeg-turbo32.deb
]])m4_dnl

# Install VirtualGL from package
COPY --from=build --chown=root:root /tmp/virtualgl/build/virtualgl_*.deb /tmp/virtualgl.deb
RUN dpkg -i /tmp/virtualgl.deb && rm -f /tmp/virtualgl.deb
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
COPY --from=build --chown=root:root /tmp/virtualgl/build32/virtualgl32_*.deb /tmp/virtualgl32.deb
RUN dpkg -i /tmp/virtualgl32.deb && rm -f /tmp/virtualgl32.deb
]])m4_dnl

# Install XRDP from package
COPY --from=build --chown=root:root /tmp/xrdp/xrdp_*.deb /tmp/xrdp.deb
RUN dpkg -i /tmp/xrdp.deb && rm -f /tmp/xrdp.deb

# Install xorgxrdp from package
COPY --from=build --chown=root:root /tmp/xorgxrdp/xorgxrdp_*.deb /tmp/xorgxrdp.deb
RUN dpkg -i /tmp/xorgxrdp.deb && rm -f /tmp/xorgxrdp.deb

# Install XRDP PulseAudio module from package
COPY --from=build --chown=root:root /tmp/xrdp-pulseaudio/xrdp-pulseaudio_*.deb /tmp/xrdp-pulseaudio.deb
RUN dpkg -i /tmp/xrdp-pulseaudio.deb && rm -f /tmp/xrdp-pulseaudio.deb

# Environment
ENV UNPRIVILEGED_USER_UID=1000
ENV UNPRIVILEGED_USER_GID=1000
ENV UNPRIVILEGED_USER_NAME=guest
ENV UNPRIVILEGED_USER_PASSWORD=password
ENV UNPRIVILEGED_USER_GROUPS=
ENV UNPRIVILEGED_USER_SHELL=/bin/bash
ENV XRDP_TLS_KEY_PATH=/etc/xrdp/key.pem
ENV XRDP_TLS_CERT_PATH=/etc/xrdp/cert.pem
ENV ENABLE_XDUMMY=false
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH=${PATH}:/usr/games:/usr/local/games
ENV PATH=${PATH}:/opt/VirtualGL/bin
ENV VGL_DISPLAY=:0
## Workaround for AMDGPU X_GLXCreatePbuffer issue:
## https://github.com/VirtualGL/virtualgl/issues/85#issuecomment-480291529
ENV VGL_FORCEALPHA=1
## Use Adwaita theme in QT applications
ENV QT_STYLE_OVERRIDE=Adwaita

# Setup locale
RUN printf '%s\n' 'en_US.UTF-8 UTF-8' > /etc/locale.gen
RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8 ||:
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Setup timezone
ENV TZ=UTC
RUN ln -snf "/usr/share/zoneinfo/${TZ:?}" /etc/localtime
RUN printf '%s\n' "${TZ:?}" > /etc/timezone

# Setup D-Bus
RUN mkdir /run/dbus/ && chown messagebus:messagebus /run/dbus/
RUN dbus-uuidgen > /etc/machine-id && ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Remove default keys and certificates
RUN rm -f "${XRDP_TLS_KEY_PATH:?}" "${XRDP_TLS_CERT_PATH:?}" /etc/ssh/ssh_host_*

# Create /etc/skel/.xsession file
RUN printf '%s\n' 'exec xfce4-session' > /etc/skel/.xsession

# Create /etc/skel/.xsessionrc file
RUN printf '%s\n' \
		'export VGL_DISPLAY=${DISPLAY:?}' \
		'export XDG_CACHE_HOME=${HOME:?}/.cache' \
		'export XDG_CONFIG_DIRS=/etc/xdg/xdg-xubuntu:/etc/xdg' \
		'export XDG_CONFIG_HOME=${HOME:?}/.config' \
		'export XDG_CURRENT_DESKTOP=XFCE' \
		'export XDG_DATA_DIRS=/usr/share/xubuntu:/usr/share/xfce4:/usr/local/share:/usr/share' \
		'export XDG_DATA_HOME=${HOME:?}/.local/share' \
		'export XDG_MENU_PREFIX=xfce-' \
		'export XDG_RUNTIME_DIR=/run/user/$(id -u)' \
		'export XDG_SESSION_DESKTOP=xubuntu' \
		'export XDG_SESSION_TYPE=x11' \
		> /etc/skel/.xsessionrc

# Create /etc/skel/.Xauthority file
RUN touch /etc/skel/.Xauthority

# Create socket directory for X server
RUN mkdir /tmp/.X11-unix/ \
	&& chmod 1777 /tmp/.X11-unix/ \
	&& chown root:root /tmp/.X11-unix/

# Configure server for use with VirtualGL
RUN vglserver_config -config +s +f -t

# Forward logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/xdummy.log
RUN ln -sf /dev/stdout /var/log/xrdp.log
RUN ln -sf /dev/stdout /var/log/xrdp-sesman.log

# Copy and enable services
COPY --chown=root:root ./scripts/service/ /etc/sv/
RUN ln -sv /etc/sv/sshd /etc/service/
RUN ln -sv /etc/sv/dbus-daemon /etc/service/
RUN ln -sv /etc/sv/xrdp /etc/service/
RUN ln -sv /etc/sv/xrdp-sesman /etc/service/

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/

# Copy config
COPY --chown=root:root ./config/ssh/sshd_config /etc/ssh/sshd_config
COPY --chown=root:root ./config/xrdp/xrdp.ini /etc/xrdp/xrdp.ini
COPY --chown=root:root ./config/xrdp/sesman.ini /etc/xrdp/sesman.ini

# Expose SSH port
EXPOSE 3322/tcp
# Expose RDP port
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/local/bin/container-init"]
