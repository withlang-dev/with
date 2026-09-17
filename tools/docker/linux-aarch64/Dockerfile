# The linux-aarch64 release host: a native linux/arm64 container on an Apple
# Silicon Mac, mirroring the packages of the GitHub runner used by
# .github/workflows/selfhost-linux-aarch64.yml (ubuntu-24.04-arm).
#
#   docker build --platform linux/arm64 -t with-aarch64-host tools/docker/linux-aarch64
#   docker volume create with-aarch64
#   docker run -it --platform linux/arm64 -v with-aarch64:/work with-aarch64-host
#
# Everything the build needs and a bare ubuntu:24.04 lacks is baked in here,
# because the failures are silent: without g++ the stage1 link dies on
# -lstdc++, and without libxml2 the SDK's ld.lld cannot start — either way the
# seed prints only "build failed". The SDK, seed, runtime bundle and clone
# live on the mounted volume (see docs/with-release-runbook.md, "Linux aarch64
# Release Host"), never in the image, so the image is pin-free.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
        ca-certificates curl git gcc g++ libc6-dev zlib1g-dev libzstd-dev libxml2-dev xz-utils strace \
        xvfb xauth libgl1-mesa-dri libgl-dev libx11-dev libxext-dev libxfixes-dev \
        libxi-dev libxinerama-dev libxrandr-dev libxcursor-dev \
    && rm -rf /var/lib/apt/lists/* \
    # The SDK's lld was linked against libxml2.so.16; Ubuntu ships .so.2.
    && ln -sf "$(ls /usr/lib/aarch64-linux-gnu/libxml2.so.2* | head -1)" /usr/lib/aarch64-linux-gnu/libxml2.so.16
WORKDIR /work/with
