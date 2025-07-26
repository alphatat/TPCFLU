FROM mcr.microsoft.com/devcontainers/base:debian

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa \
  openjdk-17-jdk \
  clang cmake ninja-build pkg-config libgtk-3-dev \
  mesa-utils \
  && apt-get clean

ENV FLUTTER_VERSION=3.32.8
RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
  && cd /opt/flutter \
  && git checkout $FLUTTER_VERSION \
  && chown -R vscode:vscode /opt/flutter \
  && git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN yes | /opt/flutter/bin/flutter doctor --android-licenses || true

RUN /opt/flutter/bin/flutter precache --universal \
  && /opt/flutter/bin/flutter config --enable-linux-desktop --enable-web

WORKDIR /workspaces/TPCFLU

RUN /opt/flutter/bin/flutter doctor