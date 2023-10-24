FROM archlinux:base-devel AS base

ENV BUILD_USER=makepkg
ENV PATH=$PATH:/opt/cuda/bin

RUN sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
RUN pacman-key --init && pacman -Sy --noconfirm archlinux-keyring && pacman -Syu --noconfirm wget dos2unix git libva-intel-driver libva-vdpau-driver libva-utils intel-media-driver libva-intel-driver openssl

RUN useradd --system --create-home $BUILD_USER \
  && echo "$BUILD_USER ALL=(ALL:ALL) NOPASSWD:/usr/sbin/pacman" > /etc/sudoers.d/$BUILD_USER

USER $BUILD_USER
WORKDIR /home/$BUILD_USER

# Install yay
RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm \
  && cd \
  && rm -rf .cache yay

RUN yes | yay -Sy --noconfirm lensfun-git comskip pod2man && \
    yes | yay -Scc

#  Use ffmpeg-nonvidia since full is currently broken
RUN yes | yay -Sy --noconfirm ffmpeg-nonvidia && \
    yes | yay -Scc

USER root

#############################################################
#### Prepare the docker with ffmpeg and hardware encoders ###
#############################################################

ENV LIBVA_DRIVERS_PATH="/usr/lib/x86_64-linux-gnu/dri" \
    LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu" \
    NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
    NVIDIA_VISIBLE_DEVICES="all" \
    DOTNET_CLI_TELEMETRY_OPTOUT=true

# Av1an Dependencies
RUN pacman -Sy --noconfirm aom vapoursynth ffms2 libvpx mkvtoolnix-cli svt-av1 vapoursynth-plugin-lsmashsource vmaf unzip rav1e

COPY --from=masterofzen/av1an:master /usr/local/bin/av1an /usr/local/bin/av1an

WORKDIR /
