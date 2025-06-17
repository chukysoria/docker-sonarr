# syntax=docker/dockerfile:1@sha256:e63addfe27b10e394a5f9f1e866961adc70d08573f1cb80f8d1a0999347b3553

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-alpine:v0.8.3-3.22@sha256:a74b3dd1344499c926571d292eeb3643f559e8725cf384ce979d6ce710c4c59f
FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_ARCH="x86_64"
ARG BUILD_EXT_RELEASE="4.0.14.2939"

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
    icu-libs=76.1-r0 \
    sqlite-libs=3.49.2-r0 \
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
