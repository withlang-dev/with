# The linux-aarch64 release host: a native linux/arm64 container on an Apple
# Silicon Mac, mirroring the packages of the GitHub runner used by
# .github/workflows/selfhost-linux-aarch64.yml (ubuntu-24.04-arm).
#
#   docker build --platform linux/arm64 -t with-aarch64-host tools/docker/linux-aarch64
#   docker volume create with-aarch64
#   docker run -it --privileged --platform linux/arm64 -v with-aarch64:/work with-aarch64-host
#
# The compiler builds and links with nothing of the host (#1915, D81): no
# gcc, libstdc++, zlib, zstd or libxml2. What is here is git and curl for the
# clone and the seed, bubblewrap for :no-host-toolchain's sandbox (run the
# container --privileged so it can make namespaces), strace for diagnosis, and
# the X/GL packages the raylib release UAT renders through. The SDK, seed and
# clone live on the mounted volume (see docs/spec/toolchain/with-release-runbook.md,
# "Linux aarch64 Release Host"), never in the image, so the image is pin-free.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
        ca-certificates curl git xz-utils strace bubblewrap \
        xvfb xauth libgl1-mesa-dri libgl-dev libx11-dev libxext-dev libxfixes-dev \
        libxi-dev libxinerama-dev libxrandr-dev libxcursor-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work/with
