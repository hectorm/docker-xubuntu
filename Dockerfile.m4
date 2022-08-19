m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:22.04]], [[FROM docker.io/ubuntu:22.04]]) AS build
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectorm/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& sed -i 's/^#\s*\(deb-src\s\)/\1/g' /etc/apt/sources.list \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
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
		cmake \
		devscripts \
		dpkg-dev \
		flex \
		git \
		intltool \
		libbz2-dev \
		libegl-dev \
		libegl1-mesa \
		libegl1-mesa-dev \
		libepoxy-dev \
		libfdk-aac-dev \
		libfreetype-dev \
		libfuse-dev \
		libgbm-dev \
		libgl-dev \
		libgles-dev \
		libglu1-mesa-dev \
		libglvnd-dev \
		libglx-dev \
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
		libxt-dev \
		libxtst-dev \
		libxv-dev \
		nasm \
		ocl-icd-opencl-dev \
		pkg-config \
		texinfo \
		x11-xkb-utils \
		xauth \
		xkb-data \
		xserver-xorg-dev \
		xsltproc \
		xutils-dev \
		zlib1g-dev \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		g++-multilib \
		libegl-dev:i386 \
		libegl1-mesa:i386 \
		libegl1-mesa-dev:i386 \
		libgl-dev:i386 \
		libgles-dev:i386 \
		libglu1-mesa-dev:i386 \
		libglvnd-dev:i386 \
		libglx-dev:i386 \
		libx11-xcb-dev:i386 \
		libxcb-glx0-dev:i386 \
		libxtst-dev:i386 \
		libxv-dev:i386 \
		ocl-icd-opencl-dev:i386 \
]])m4_dnl
	&& apt-get clean

# Build libjpeg-turbo
ARG LIBJPEG_TURBO_TREEISH=2.1.4
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
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
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
ARG VIRTUALGL_TREEISH=3.0.1
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
		-D VGL_EGLBACKEND=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./virtualgl_*.deb
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
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
		-D VGL_EGLBACKEND=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./virtualgl32_*.deb
]])m4_dnl

# Build TurboVNC
ARG TURBOVNC_TREEISH=3.0.1
ARG TURBOVNC_REMOTE=https://github.com/TurboVNC/turbovnc.git
RUN mkdir /tmp/turbovnc/
WORKDIR /tmp/turbovnc/
RUN git clone "${TURBOVNC_REMOTE:?}" ./
RUN git checkout "${TURBOVNC_TREEISH:?}"
RUN git submodule update --init --recursive
RUN mkdir /tmp/turbovnc/build/
WORKDIR /tmp/turbovnc/build/
RUN cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=turbovnc \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/TurboVNC \
		-D TVNC_BUILDSERVER=1 \
		-D TVNC_BUILDWEBSERVER=0 \
		-D TVNC_BUILDVIEWER=0 \
		-D TVNC_BUILDHELPER=0 \
		-D TVNC_SYSTEMLIBS=1 \
		-D TVNC_SYSTEMX11=1 \
		-D TVNC_DLOPENSSL=1 \
		-D TVNC_USEPAM=1 \
		-D TVNC_GLX=1 \
		-D TVNC_NVCONTROL=1 \
		../
RUN make -j"$(nproc)"
RUN make deb
RUN dpkg -i ./turbovnc_*.deb

# Build xrdp
ARG XRDP_TREEISH=v0.9.19
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
RUN checkinstall --default --pkgname=xrdp --pkgversion=9:999 --pkgrelease=0

# Build xorgxrdp
ARG XORGXRDP_TREEISH=v0.2.18
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
ARG XRDP_PULSEAUDIO_TREEISH=v0.6
ARG XRDP_PULSEAUDIO_REMOTE=https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/
RUN DEBIAN_FRONTEND=noninteractive apt-get build-dep -y pulseaudio
RUN apt-get source pulseaudio && mv ./pulseaudio-*/ ./pulseaudio/
WORKDIR /tmp/pulseaudio/
RUN meson ./build/
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
## "main" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:22.04]], [[FROM docker.io/ubuntu:22.04]]) AS main
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectorm/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
	&& dpkg --add-architecture i386 \
]])m4_dnl
	&& apt-get update \
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		at-spi2-core \
		ca-certificates \
		catatonit \
		dbus \
		dbus-x11 \
		libbz2-1.0 \
		libegl1 \
		libegl1-mesa \
		libepoxy0 \
		libfdk-aac2 \
		libfreetype6 \
		libfuse2 \
		libgbm1 \
		libgl1 \
		libgl1-mesa-dri \
		libgles2 \
		libglu1 \
		libglvnd0 \
		libglx-mesa0 \
		libmp3lame0 \
		libopus0 \
		libpam0g \
		libpixman-1-0 \
		libpulse0 \
		libssl3 \
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
		libxt6 \
		libxtst6 \
		libxv1 \
		locales \
		mesa-opencl-icd \
		mesa-va-drivers \
		mesa-vdpau-drivers \
		mesa-vulkan-drivers \
		ocl-icd-opencl-dev \
		openssh-server \
		openssl \
		policykit-1 \
		pulseaudio \
		runit \
		tzdata \
		udev \
		xauth \
		xkb-data \
		xserver-xorg-core \
		xserver-xorg-input-evdev \
		xserver-xorg-input-joystick \
		xserver-xorg-input-libinput \
		xserver-xorg-video-dummy \
		xserver-xorg-video-fbdev \
		xserver-xorg-video-vesa \
		zlib1g \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libegl1:i386 \
		libegl1-mesa:i386 \
		libgl1:i386 \
		libgl1-mesa-dri:i386 \
		libgles2:i386 \
		libglu1:i386 \
		libglvnd0:i386 \
		libglx-mesa0:i386 \
		libx11-xcb1:i386 \
		libxcb-glx0:i386 \
		libxtst6:i386 \
		libxv1:i386 \
		mesa-opencl-icd:i386 \
		mesa-va-drivers:i386 \
		mesa-vdpau-drivers:i386 \
		mesa-vulkan-drivers:i386 \
		ocl-icd-opencl-dev:i386 \
]])m4_dnl
m4_ifelse(ENABLE_AMD_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-amdgpu1 \
		xserver-xorg-video-amdgpu \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-amdgpu1:i386 \
]])m4_dnl
]])m4_dnl
m4_ifelse(ENABLE_INTEL_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		intel-opencl-icd \
		libdrm-intel1 \
		xserver-xorg-video-intel \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-intel1:i386 \
]])m4_dnl
]])m4_dnl
m4_ifelse(ENABLE_NVIDIA_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-nouveau2 \
		libnvidia-compute-515 \
		libnvidia-decode-515 \
		libnvidia-encode-515 \
		libnvidia-extra-515 \
		libnvidia-fbc1-515 \
		libnvidia-gl-515 \
		xserver-xorg-video-nouveau \
		xserver-xorg-video-nvidia-515 \
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-nouveau2:i386 \
		libnvidia-compute-515:i386 \
		libnvidia-decode-515:i386 \
		libnvidia-encode-515:i386 \
		libnvidia-extra-515:i386 \
		libnvidia-fbc1-515:i386 \
		libnvidia-gl-515:i386 \
]])m4_dnl
]])m4_dnl
	&& apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		adwaita-icon-theme-full \
		adwaita-qt \
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
		epiphany-browser \
		exo-utils \
		file \
		fonts-dejavu \
		fonts-liberation \
		fonts-noto \
		fonts-noto-color-emoji \
		fonts-ubuntu \
		fuse3 \
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
		librsvg2-common \
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
		pulseaudio-utils \
		ristretto \
		strace \
		sudo \
		thunar-archive-plugin \
		tumbler \
		unzip \
		usbutils \
		vulkan-tools \
		wget \
		x11-utils \
		x11-xkb-utils \
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
		xterm \
		xubuntu-default-settings \
		xutils \
		xz-utils \
		zenity \
		zip \
	&& rm -rf /var/lib/apt/lists/*

# Install libjpeg-turbo from package
RUN --mount=type=bind,from=build,source=/tmp/libjpeg-turbo/,target=/tmp/libjpeg-turbo/ dpkg -i /tmp/libjpeg-turbo/build/libjpeg-turbo_*.deb
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
RUN --mount=type=bind,from=build,source=/tmp/libjpeg-turbo/,target=/tmp/libjpeg-turbo/ dpkg -i /tmp/libjpeg-turbo/build32/libjpeg-turbo32_*.deb
]])m4_dnl

# Install VirtualGL from package
RUN --mount=type=bind,from=build,source=/tmp/virtualgl/,target=/tmp/virtualgl/ dpkg -i /tmp/virtualgl/build/virtualgl_*.deb
m4_ifelse(ENABLE_32BIT_SUPPORT, 1, [[m4_dnl
RUN --mount=type=bind,from=build,source=/tmp/virtualgl/,target=/tmp/virtualgl/ dpkg -i /tmp/virtualgl/build32/virtualgl32_*.deb
]])m4_dnl

# Install TurboVNC from package
RUN --mount=type=bind,from=build,source=/tmp/turbovnc/,target=/tmp/turbovnc/ dpkg -i /tmp/turbovnc/build/turbovnc_*.deb

# Install xrdp from package
RUN --mount=type=bind,from=build,source=/tmp/xrdp/,target=/tmp/xrdp/ dpkg -i /tmp/xrdp/xrdp_*.deb

# Install xorgxrdp from package
RUN --mount=type=bind,from=build,source=/tmp/xorgxrdp/,target=/tmp/xorgxrdp/ dpkg -i /tmp/xorgxrdp/xorgxrdp_*.deb

# Install xrdp PulseAudio module from package
RUN --mount=type=bind,from=build,source=/tmp/xrdp-pulseaudio/,target=/tmp/xrdp-pulseaudio/ dpkg -i /tmp/xrdp-pulseaudio/xrdp-pulseaudio_*.deb

# Environment
ENV UNPRIVILEGED_USER_UID=1000
ENV UNPRIVILEGED_USER_GID=1000
ENV UNPRIVILEGED_USER_NAME=user
ENV UNPRIVILEGED_USER_PASSWORD=password
ENV UNPRIVILEGED_USER_GROUPS=
ENV UNPRIVILEGED_USER_SHELL=/bin/bash
ENV XRDP_TLS_KEY_PATH=/etc/xrdp/key.pem
ENV XRDP_TLS_CRT_PATH=/etc/xrdp/cert.pem
ENV ENABLE_XDUMMY=false
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
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
ENV PATH=/opt/libjpeg-turbo/bin:/opt/VirtualGL/bin:/opt/TurboVNC/bin:${PATH}

# Setup D-Bus
RUN mkdir /run/dbus/ && chown messagebus:messagebus /run/dbus/
RUN dbus-uuidgen > /etc/machine-id
RUN ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Make sesman read environment variables
RUN printf '%s\n' 'session required pam_env.so readenv=1' >> /etc/pam.d/xrdp-sesman

# Remove default keys and certificates
RUN rm -f /etc/ssh/ssh_host_*
RUN rm -f "${XRDP_TLS_KEY_PATH:?}" "${XRDP_TLS_CRT_PATH:?}"

# Forward logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/xdummy.log
RUN ln -sf /dev/stdout /var/log/xrdp.log
RUN ln -sf /dev/stdout /var/log/xrdp-sesman.log

# Copy and enable services
COPY --chown=root:root ./scripts/service/ /etc/sv/
RUN find /etc/sv/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/sv/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN ln -sv /etc/sv/dbus-daemon /etc/service/
RUN ln -sv /etc/sv/sshd /etc/service/
RUN ln -sv /etc/sv/udevadm-trigger /etc/service/
RUN ln -sv /etc/sv/udevd /etc/service/
RUN ln -sv /etc/sv/xrdp /etc/service/
RUN ln -sv /etc/sv/xrdp-sesman /etc/service/

# Copy SSH config
COPY --chown=root:root ./config/ssh/ /etc/ssh/
RUN find /etc/ssh/sshd_config -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy X11 config
COPY --chown=root:root ./config/X11/ /etc/X11/
RUN find /etc/X11/xorg.conf.d/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/X11/xorg.conf.d/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy xrdp config
COPY --chown=root:root ./config/xrdp/ /etc/xrdp/
RUN find /etc/xrdp/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/xrdp/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'
RUN find /etc/xrdp/ -type f -name '*.sh' -not -perm 0755 -exec chmod 0755 '{}' ';'

# Copy PulseAudio config
COPY --chown=root:root ./config/pulse/ /etc/pulse/
RUN find /etc/pulse/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/pulse/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy skeleton files
COPY --chown=root:root ./config/skel/ /etc/skel/
RUN find /etc/skel/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /etc/skel/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/
RUN find /usr/local/bin/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
RUN find /usr/local/bin/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'

# Expose SSH port
EXPOSE 3322/tcp
# Expose RDP port
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/local/bin/container-init"]
