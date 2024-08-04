m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:24.04]], [[FROM docker.io/ubuntu:24.04]]) AS build

SHELL ["/bin/sh", "-euc"]

# Enable source repositories
RUN <<-EOF
	sed -i '/^Types: deb$/s/$/ deb-src/' /etc/apt/sources.list.d/ubuntu.sources
EOF

# Install packages
RUN <<-EOF
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		autoconf \
		automake \
		bison \
		build-essential \
		ca-certificates \
		cmake \
		dbus-x11 \
		devscripts \
		dpkg-dev \
		flex \
		git \
		intltool \
		libbz2-dev \
		libegl-dev \
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
		zlib1g-dev
	apt-get clean
EOF

# Build libjpeg-turbo
ARG LIBJPEG_TURBO_TREEISH=3.0.3
ARG LIBJPEG_TURBO_REMOTE=https://github.com/libjpeg-turbo/libjpeg-turbo.git
WORKDIR /tmp/libjpeg-turbo/
RUN <<-EOF
	git clone "${LIBJPEG_TURBO_REMOTE:?}" ./
	git checkout "${LIBJPEG_TURBO_TREEISH:?}"
	git submodule update --init --recursive
EOF
WORKDIR /tmp/libjpeg-turbo/build/
RUN <<-EOF
	cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=libjpeg-turbo \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/libjpeg-turbo \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		../
	make -j"$(nproc)" install
EOF

# Build VirtualGL
ARG VIRTUALGL_TREEISH=3.1.1
ARG VIRTUALGL_REMOTE=https://github.com/VirtualGL/virtualgl.git
WORKDIR /tmp/virtualgl/
RUN <<-EOF
	git clone "${VIRTUALGL_REMOTE:?}" ./
	git checkout "${VIRTUALGL_TREEISH:?}"
	git submodule update --init --recursive
EOF
WORKDIR /tmp/virtualgl/build/
RUN <<-EOF
	cmake ./ \
		-G 'Unix Makefiles' \
		-D PKGNAME=virtualgl \
		-D CMAKE_BUILD_TYPE=Release \
		-D CMAKE_INSTALL_PREFIX=/opt/VirtualGL \
		-D CMAKE_POSITION_INDEPENDENT_CODE=1 \
		-D VGL_EGLBACKEND=1 \
		../
	make -j"$(nproc)" install
EOF

# Build TurboVNC
ARG TURBOVNC_TREEISH=3.1.1
ARG TURBOVNC_REMOTE=https://github.com/TurboVNC/turbovnc.git
WORKDIR /tmp/turbovnc/
RUN <<-EOF
	git clone "${TURBOVNC_REMOTE:?}" ./
	git checkout "${TURBOVNC_TREEISH:?}"
	git submodule update --init --recursive
EOF
WORKDIR /tmp/turbovnc/build/
RUN <<-EOF
	cmake ./ \
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
	make -j"$(nproc)" install
EOF

# Build xrdp
ARG XRDP_TREEISH=v0.10.1
ARG XRDP_REMOTE=https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp/
RUN <<-EOF
	git clone "${XRDP_REMOTE:?}" ./
	git checkout "${XRDP_TREEISH:?}"
	git submodule update --init --recursive
EOF
RUN <<-EOF
	./bootstrap
	./configure \
		--prefix=/opt/xrdp \
		--enable-strict-locations \
		--enable-vsock \
		--enable-tjpeg \
		--enable-fuse \
		--enable-fdkaac \
		--enable-opus \
		--enable-mp3lame \
		--enable-pixman \
		--enable-ipv6
	make -j"$(nproc)" install
	rm -f /opt/xrdp/etc/xrdp/rsakeys.ini /opt/xrdp/etc/xrdp/*.pem
EOF

# Build xorgxrdp
ARG XORGXRDP_TREEISH=v0.10.2
ARG XORGXRDP_REMOTE=https://github.com/neutrinolabs/xorgxrdp.git
WORKDIR /tmp/xorgxrdp/
RUN <<-EOF
	git clone "${XORGXRDP_REMOTE:?}" ./
	git checkout "${XORGXRDP_TREEISH:?}"
	git submodule update --init --recursive
EOF
RUN <<-EOF
	./bootstrap
	./configure \
		--prefix=/opt/xrdp \
		--enable-strict-locations \
		--enable-glamor \
		PKG_CONFIG_PATH=/opt/xrdp/lib/pkgconfig
	make -j"$(nproc)" install
EOF

# Build xrdp PulseAudio module
ARG XRDP_PULSEAUDIO_TREEISH=v0.7
ARG XRDP_PULSEAUDIO_REMOTE=https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/
RUN <<-EOF
	DEBIAN_FRONTEND=noninteractive apt-get build-dep -y pulseaudio
	apt-get source pulseaudio && mv ./pulseaudio-*/ ./pulseaudio/
	meson setup ./pulseaudio/build/ ./pulseaudio/
EOF
WORKDIR /tmp/pulseaudio-module-xrdp/
RUN <<-EOF
	git clone "${XRDP_PULSEAUDIO_REMOTE:?}" ./
	git checkout "${XRDP_PULSEAUDIO_TREEISH:?}"
	git submodule update --init --recursive
EOF
RUN <<-EOF
	./bootstrap
	./configure \
		--prefix=/opt/xrdp \
		--with-module-dir=/opt/xrdp/lib/pulse/modules \
		PKG_CONFIG_PATH=/opt/xrdp/lib/pkgconfig \
		PULSE_DIR=/tmp/pulseaudio/
	make -j"$(nproc)" install
EOF

##################################################
## "main" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:24.04]], [[FROM docker.io/ubuntu:24.04]]) AS main

SHELL ["/bin/sh", "-euc"]

# Copy APT config
COPY --chown=root:root ./config/apt/preferences.d/ /etc/apt/preferences.d/
RUN <<-EOF
	find /etc/apt/preferences.d/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
	find /etc/apt/preferences.d/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'
EOF

# Install base packages
RUN <<-EOF
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		at-spi2-core \
		ca-certificates \
		catatonit \
		curl \
		dbus \
		dbus-x11 \
		gnupg \
		libbz2-1.0 \
		libegl1 \
		libepoxy0 \
		libfdk-aac2 \
		libfreetype6 \
		libfuse2t64 \
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
		libssl3t64 \
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
		libxt6t64 \
		libxtst6 \
		libxv1 \
		locales \
		lsb-release \
		mesa-opencl-icd \
		mesa-va-drivers \
		mesa-vdpau-drivers \
		mesa-vulkan-drivers \
		ocl-icd-opencl-dev \
		openssh-server \
		openssl \
		perl-base \
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
		zlib1g
m4_ifelse(ENABLE_AMD_SUPPORT, 1, [[m4_dnl
	apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-amdgpu1 \
		xserver-xorg-video-amdgpu
]])m4_dnl
m4_ifelse(ENABLE_INTEL_SUPPORT, 1, [[m4_dnl
	apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		intel-opencl-icd \
		libdrm-intel1 \
		xserver-xorg-video-intel
]])m4_dnl
m4_ifelse(ENABLE_NVIDIA_SUPPORT, 1, [[m4_dnl
	apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		libdrm-nouveau2 \
		libnvidia-cfg1-550 \
		libnvidia-compute-550 \
		libnvidia-decode-550 \
		libnvidia-encode-550 \
		libnvidia-extra-550 \
		libnvidia-fbc1-550 \
		libnvidia-gl-550 \
		xserver-xorg-video-nouveau \
		xserver-xorg-video-nvidia-550
]])m4_dnl
	rm -rf /var/lib/apt/lists/*
	rm -f /etc/ssh/ssh_host_*_key
EOF

# Add Mozilla Team repository
RUN <<-EOF
	curl --proto '=https' --tlsv1.3 -sSf 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0AB215679C571D1C8325275B9BDB3D89CE49EC21' | gpg --dearmor -o /etc/apt/trusted.gpg.d/mozillateam.gpg
	printf '%s\n' "deb [signed-by=/etc/apt/trusted.gpg.d/mozillateam.gpg] https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/mozillateam.list
EOF

# Install extra packages
RUN <<-EOF
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		adwaita-icon-theme-full \
		adwaita-qt \
		audacity \
		bash \
		bash-completion \
		binutils \
		clinfo \
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
		fuse3 \
		git \
		gnome-keyring \
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
		media-types \
		menu \
		menu-xdg \
		menulibre \
		mesa-utils \
		mesa-utils-extra \
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
		xfce4-panel \
		xfce4-panel-profiles \
		xfce4-pulseaudio-plugin \
		xfce4-screenshooter \
		xfce4-taskmanager \
		xfce4-terminal \
		xfce4-whiskermenu-plugin \
		xfonts-base \
		xinput \
		xterm \
		xubuntu-default-settings \
		xutils \
		xz-utils \
		zenity \
		zip
	rm -rf /var/lib/apt/lists/*
EOF

# Copy libjpeg-turbo build
COPY --from=build /opt/libjpeg-turbo/ /opt/libjpeg-turbo/

# Copy VirtualGL build
COPY --from=build /opt/VirtualGL/ /opt/VirtualGL/

# Copy TurboVNC build
COPY --from=build /opt/TurboVNC/ /opt/TurboVNC/

# Copy xrdp, xorgxrdp and PulseAudio module builds
COPY --from=build /opt/xrdp/ /opt/xrdp/

# Environment
ENV SVDIR=/etc/service/
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
ENV PATH=/opt/libjpeg-turbo/bin:/opt/VirtualGL/bin:/opt/TurboVNC/bin:/opt/xrdp/sbin:/opt/xrdp/bin:${PATH}
ENV UNPRIVILEGED_USER_UID=1000
ENV UNPRIVILEGED_USER_GID=1000
ENV UNPRIVILEGED_USER_NAME=user
ENV UNPRIVILEGED_USER_PASSWORD=password
ENV UNPRIVILEGED_USER_GROUPS=
ENV UNPRIVILEGED_USER_SHELL=/bin/bash
ENV UNPRIVILEGED_USER_HOME=/home/user
ENV SERVICE_XRDP_BOOTSTRAP_ENABLED=false
ENV SERVICE_XORG_HEADLESS_ENABLED=false
ENV XRDP_RSAKEYS_PATH=/etc/xrdp/rsakeys.ini
ENV XRDP_TLS_KEY_PATH=/etc/xrdp/key.pem
ENV XRDP_TLS_CRT_PATH=/etc/xrdp/cert.pem
ENV STARTUP=xfce4-session
ENV DESKTOP_SESSION=xubuntu
ENV QT_STYLE_OVERRIDE=Adwaita

# Setup locale
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN <<-EOF
	printf '%s\n' "${LANG:?} UTF-8" > /etc/locale.gen
	localedef -c -i "${LANG%%.*}" -f UTF-8 "${LANG:?}" ||:
EOF

# Setup timezone
ENV TZ=UTC
RUN <<-EOF
	printf '%s\n' "${TZ:?}" > /etc/timezone
	ln -snf "/usr/share/zoneinfo/${TZ:?}" /etc/localtime
EOF

# Setup D-Bus
RUN <<-EOF
	dbus-uuidgen > /etc/machine-id
	ln -sf /etc/machine-id /var/lib/dbus/machine-id
EOF

# Make sesman read environment variables
RUN <<-EOF
	printf '%s\n' 'session required pam_env.so readenv=1' >> /etc/pam.d/xrdp-sesman
EOF

# Remove default user and group
RUN <<-EOF
	if id -u "${UNPRIVILEGED_USER_UID:?}" >/dev/null 2>&1; then userdel -f "$(id -nu "${UNPRIVILEGED_USER_UID:?}")"; fi
	if id -g "${UNPRIVILEGED_USER_GID:?}" >/dev/null 2>&1; then groupdel "$(id -nu "${UNPRIVILEGED_USER_GID:?}")"; fi
EOF

# Create symlinks for xrdp RSA keys and TLS certificates
RUN <<-EOF
	ln -svf "${XRDP_RSAKEYS_PATH:?}" /opt/xrdp/etc/xrdp/rsakeys.ini
	ln -svf "${XRDP_TLS_KEY_PATH:?}" /opt/xrdp/etc/xrdp/key.pem
	ln -svf "${XRDP_TLS_CRT_PATH:?}" /opt/xrdp/etc/xrdp/cert.pem
EOF

# Forward logs to Docker log collector
RUN <<-EOF
	ln -svf /dev/stdout /var/log/xorg-headless.log
	ln -svf /dev/stdout /var/log/xrdp.log
	ln -svf /dev/stdout /var/log/xrdp-sesman.log
EOF

# Copy and enable services
COPY --chown=root:root ./scripts/service/ /etc/sv/
RUN <<-EOF
	find /etc/sv/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
	find /etc/sv/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'
	ln -sv /etc/sv/dbus-daemon "${SVDIR:?}"
	ln -sv /etc/sv/sshd "${SVDIR:?}"
	ln -sv /etc/sv/udevadm-trigger "${SVDIR:?}"
	ln -sv /etc/sv/udevd "${SVDIR:?}"
	ln -sv /etc/sv/xrdp "${SVDIR:?}"
	ln -sv /etc/sv/xrdp-sesman "${SVDIR:?}"
EOF

# Copy SSH config
COPY --chown=root:root ./config/ssh/ /etc/ssh/
RUN <<-EOF
	find /etc/ssh/sshd_config -type f -not -perm 0644 -exec chmod 0644 '{}' ';'
EOF

# Copy X11 config
COPY --chown=root:root ./config/X11/ /etc/X11/
RUN <<-EOF
	find /etc/X11/xorg.conf.d/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
	find /etc/X11/xorg.conf.d/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'
EOF

# Copy xrdp config
COPY --chown=root:root ./config/xrdp/ /opt/xrdp/etc/xrdp/
RUN <<-EOF
	find /opt/xrdp/etc/xrdp/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
	find /opt/xrdp/etc/xrdp/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'
	find /opt/xrdp/etc/xrdp/ -type f -name '*.sh' -not -perm 0755 -exec chmod 0755 '{}' ';'
EOF

# Copy PulseAudio config
COPY --chown=root:root ./config/pulse/ /etc/pulse/
RUN <<-EOF
	find /etc/pulse/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
	find /etc/pulse/ -type f -not -perm 0644 -exec chmod 0644 '{}' ';'
EOF

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/local/bin/
RUN <<-EOF
	find /usr/local/bin/ -type d -not -perm 0755 -exec chmod 0755 '{}' ';'
	find /usr/local/bin/ -type f -not -perm 0755 -exec chmod 0755 '{}' ';'
EOF

# SSH
EXPOSE 3322/tcp
# RDP
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/bin/catatonit", "--", "/usr/local/bin/container-init"]
