# syntax=docker/dockerfile:1

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:v0.1.6-jammy

FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_EXT_RELEASE="4.0.0.703"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# set environment variables
ENV XDG_CONFIG_HOME="/config/xdg"
ENV SONARR_BRANCH="develop"

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    xmlstarlet=1.6.1-2.1 && \
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
    "https://download.sonarr.tv/v4/${SONARR_BRANCH}/${BUILD_EXT_RELEASE}/Sonarr.${SONARR_BRANCH}.${BUILD_EXT_RELEASE}.linux-${ARCH}.tar.gz" && \
  tar xzf \
    /tmp/sonarr.tar.gz -C \
    /app/sonarr/bin --strip-components=1 && \
  echo -e "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${BUILD_VERSION}\nPackageAuthor=[linuxserver.io](https://linuxserver.io)" > /app/sonarr/package_info && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /app/sonarr/bin/Sonarr.Update \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8989

VOLUME /config
