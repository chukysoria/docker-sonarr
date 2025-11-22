# syntax=docker/dockerfile:1@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-alpine:v0.8.15-3.22@sha256:3af92bd2458460cfd90f537a9ed6517e54ad6566fa57ba0955ca314c40e90317
FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_ARCH="x86_64"
ARG BUILD_EXT_RELEASE="4.0.16.2944"

LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# set environment variables
ENV XDG_CONFIG_HOME="/config/xdg" \
  SONARR_CHANNEL="v4-stable" \
  SONARR_BRANCH="main" \
  COMPlus_EnableDiagnostics=0 \
  TMPDIR=/run/sonarr-temp

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    icu-libs=76.1-r1 \
    sqlite-libs=3.49.2-r1 \
    xmlstarlet=1.6.1-r2 && \
  echo "**** install sonarr ****" && \
  mkdir -p /app/sonarr/bin && \
  case ${BUILD_ARCH} in \
      "armv7") \
          ARCH="arm" \
          ;; \
      "aarch64") \
          ARCH="arm64" \
          ;; \
      "x86_64") \
          ARCH="x64" \
          ;; \
      *) \
          echo "Unknown architecture: ${BUILD_ARCH}" && \
          exit 1 \
          ;; \
  esac && \
  curl -o \
    /tmp/sonarr.tar.gz -L \
    "https://github.com/Sonarr/Sonarr/releases/download/v${BUILD_EXT_RELEASE}/Sonarr.${SONARR_BRANCH}.${BUILD_EXT_RELEASE}.linux-musl-${ARCH}.tar.gz" && \
  tar xzf \
    /tmp/sonarr.tar.gz -C \
    /app/sonarr/bin --strip-components=1 && \
  echo -e "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${BUILD_VERSION}\nPackageAuthor=[linuxserver.io](https://linuxserver.io)" > /app/sonarr/package_info && \
  echo "**** cleanup ****" && \
  rm -rf \
    /app/sonarr/bin/Sonarr.Update \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8989

VOLUME /config

HEALTHCHECK --interval=30s --timeout=30s --start-period=2m --start-interval=5s --retries=5 CMD ["/etc/s6-overlay/s6-rc.d/svc-sonarr/data/check"]
