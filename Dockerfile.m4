m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:20.04]], [[FROM docker.io/ubuntu:20.04]]) AS build
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& sed -i 's/^#\s*\(deb-src\s\)/\1/g' /etc/apt/sources.list \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
	&& dpkg --add-architecture i386 \
]])m4_dnl
	&& apt-get update \
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		autoconf \
		automake \
		bison \
		build-essential \
		ca-certificates \
		checkinstall \
		devscripts \
		dpkg-dev \
		flex \
		cmake \
		git \
		intltool \
		libegl1-mesa \
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
		xserver-xorg-dev \
		xsltproc \
		xutils-dev \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		g++-multilib \
		libegl1-mesa:i386 \
		libegl1-mesa-dev:i386 \
		libgl1-mesa-dev:i386 \
		libglu1-mesa-dev:i386 \
		libx11-xcb-dev:i386 \
		libxcb-glx0-dev:i386 \
		libxtst-dev:i386 \
		libxv-dev:i386 \
		ocl-icd-opencl-dev:i386 \
]])m4_dnl
	&& apt-get clean

# Build libjpeg-turbo
ARG LIBJPEG_TURBO_TREEISH=2.1.0
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
RUN cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=libjpeg-turbo \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/libjpeg-turbo \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		-D CMAKE_C_FLAGS='-m32' \
		-D CMAKE_CXX_FLAGS='-m32' \
		-D CMAKE_EXE_LINKER_FLAGS='-m32' \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./libjpeg-turbo32_*.deb
]])m4_dnl

# Build VirtualGL
ARG VIRTUALGL_TREEISH=2.6.5
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
RUN cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=virtualgl \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/VirtualGL \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		-D CMAKE_C_FLAGS='-m32' \
		-D CMAKE_CXX_FLAGS='-m32' \
		-D CMAKE_EXE_LINKER_FLAGS='-m32' \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./virtualgl32_*.deb
]])m4_dnl

# Build xrdp
ARG XRDP_TREEISH=v0.9.15
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
		--enable-pixman \
		CFLAGS='-Wno-format'
RUN make -j"$(nproc)"
RUN checkinstall --default --pkgname=xrdp --pkgversion=9:999 --pkgrelease=0

# Build xorgxrdp
ARG XORGXRDP_TREEISH=v0.2.15
ARG XORGXRDP_REMOTE=https://github.com/neutrinolabs/xorgxrdp.git
RUN mkdir /tmp/xorgxrdp/
WORKDIR /tmp/xorgxrdp/
RUN git clone "${XORGXRDP_REMOTE:?}" ./
RUN git checkout "${XORGXRDP_TREEISH:?}"
RUN git submodule update --init --recursive
RUN ./bootstrap
RUN ./configure --enable-glamor
RUN make -j"$(nproc)"
RUN checkinstall --default --pkgname=xorgxrdp --pkgversion=9:999 --pkgrelease=0

# Build xrdp PulseAudio module
ARG XRDP_PULSEAUDIO_TREEISH=v0.5
ARG XRDP_PULSEAUDIO_REMOTE=https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/
RUN DEBIAN_FRONTEND=noninteractive apt-get build-dep -y pulseaudio
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
RUN checkinstall --default --pkgname=xrdp-pulseaudio --pkgversion=9:999 --pkgrelease=0

##################################################
## "xubuntu" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:20.04]], [[FROM docker.io/ubuntu:20.04]]) AS xubuntu
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
	&& dpkg --add-architecture i386 \
]])m4_dnl
	&& apt-get update \
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		at-spi2-core \
		ca-certificates \
		dbus \
		dbus-x11 \
		libegl1 \
		libegl1-mesa \
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
		tini \
		tzdata \
		xserver-xorg-core \
		xserver-xorg-input-all \
		xserver-xorg-input-evdev \
		xserver-xorg-input-joystick \
		xserver-xorg-video-all \
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libegl1:i386 \
		libegl1-mesa:i386 \
		libgl1:i386 \
		libgl1-mesa-dri:i386 \
		libgl1-mesa-glx:i386 \
		libglu1:i386 \
		libx11-xcb1:i386 \
		libxcb-glx0:i386 \
		libxtst6:i386 \
		libxv1:i386 \
		mesa-opencl-icd:i386 \
		mesa-va-drivers:i386 \
		mesa-vdpau-drivers:i386 \
		mesa-vulkan-drivers:i386 \
		ocl-icd-libopencl1:i386 \
]])m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		adwaita-qt \
		apt-transport-https \
		apt-utils \
		audacity \
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
		lshw \
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
		parole \
		pavucontrol \
		pciutils \
		procps \
		psmisc \
		ristretto \
		strace \
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

# Install libjpeg-turbo from package
COPY --from=build --chown=root:root /tmp/libjpeg-turbo/build/libjpeg-turbo_*.deb /opt/pkg/libjpeg-turbo.deb
RUN dpkg -i /opt/pkg/libjpeg-turbo.deb
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
COPY --from=build --chown=root:root /tmp/libjpeg-turbo/build32/libjpeg-turbo32_*.deb /opt/pkg/libjpeg-turbo32.deb
RUN dpkg -i /opt/pkg/libjpeg-turbo32.deb
]])m4_dnl

# Install VirtualGL from package
COPY --from=build --chown=root:root /tmp/virtualgl/build/virtualgl_*.deb /opt/pkg/virtualgl.deb
RUN dpkg -i /opt/pkg/virtualgl.deb
m4_ifelse(ENABLE_32BIT, 1, [[m4_dnl
COPY --from=build --chown=root:root /tmp/virtualgl/build32/virtualgl32_*.deb /opt/pkg/virtualgl32.deb
RUN dpkg -i /opt/pkg/virtualgl32.deb
]])m4_dnl

# Install xrdp from package
COPY --from=build --chown=root:root /tmp/xrdp/xrdp_*.deb /opt/pkg/xrdp.deb
RUN dpkg -i /opt/pkg/xrdp.deb

# Install xorgxrdp from package
COPY --from=build --chown=root:root /tmp/xorgxrdp/xorgxrdp_*.deb /opt/pkg/xorgxrdp.deb
RUN dpkg -i /opt/pkg/xorgxrdp.deb

# Install xrdp PulseAudio module from package
COPY --from=build --chown=root:root /tmp/xrdp-pulseaudio/xrdp-pulseaudio_*.deb /opt/pkg/xrdp-pulseaudio.deb
RUN dpkg -i /opt/pkg/xrdp-pulseaudio.deb

# Environment
ENV UNPRIVILEGED_USER_UID=1000
ENV UNPRIVILEGED_USER_GID=1000
ENV UNPRIVILEGED_USER_NAME=guest
ENV UNPRIVILEGED_USER_PASSWORD=password
ENV UNPRIVILEGED_USER_GROUPS=
ENV UNPRIVILEGED_USER_SHELL=/bin/bash
ENV XRDP_TLS_KEY_PATH=/etc/xrdp/key.pem
ENV XRDP_TLS_CRT_PATH=/etc/xrdp/cert.pem
ENV ENABLE_XDUMMY=false
ENV VGL_DISPLAY=:0
## Workaround for AMDGPU X_GLXCreatePbuffer issue:
## https://github.com/VirtualGL/virtualgl/issues/85#issuecomment-480291529
ENV VGL_FORCEALPHA=1
## Use Adwaita theme in QT applications
ENV QT_STYLE_OVERRIDE=Adwaita

# Setup locale
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN printf '%s\n' "${LANG:?} UTF-8" > /etc/locale.gen \
	&& localedef -c -i "${LANG%%.*}" -f UTF-8 "${LANG:?}" ||:

# Setup timezone
ENV TZ=UTC
RUN printf '%s\n' "${TZ:?}" > /etc/timezone \
	&& ln -snf "/usr/share/zoneinfo/${TZ:?}" /etc/localtime

# Setup PATH
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH=${PATH}:/usr/games:/usr/local/games
ENV PATH=${PATH}:/opt/VirtualGL/bin

# Setup D-Bus
RUN mkdir /run/dbus/ && chown messagebus:messagebus /run/dbus/
RUN dbus-uuidgen > /etc/machine-id
RUN ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Make sesman read environment variables
RUN printf '%s\n' 'session required pam_env.so readenv=1' >> /etc/pam.d/xrdp-sesman

# Configure server for use with VirtualGL
RUN vglserver_config -config +s +f -t

# Remove default keys and certificates
RUN rm -f /etc/ssh/ssh_host_*
RUN rm -f "${XRDP_TLS_KEY_PATH:?}" "${XRDP_TLS_CRT_PATH:?}"

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
COPY --chown=root:root ./config/ssh/ /etc/ssh/
COPY --chown=root:root ./config/xrdp/ /etc/xrdp/
COPY --chown=root:root ./config/skel/ /etc/skel/
COPY --chown=root:root ./config/pulse/ /etc/pulse/

# Expose SSH port
EXPOSE 3322/tcp
# Expose RDP port
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/local/bin/container-init"]
