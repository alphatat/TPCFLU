FROM mcr.microsoft.com/devcontainers/base:debian

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa \
  openjdk-17-jdk \
  && apt-get clean

# Install Flutter SDK
ENV FLUTTER_VERSION=3.22.1
RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
  && cd /opt/flutter \
  && git checkout $FLUTTER_VERSION \
  && /opt/flutter/bin/flutter doctor

# Add Flutter to PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Accept Android licenses (only needed for Android builds)
RUN yes | /opt/flutter/bin/flutter doctor --android-licenses || true

# Pre-download Flutter dependencies to speed up boot
RUN flutter precache --universal && flutter config --enable-linux-desktop --enable-web

# Set working directory
WORKDIR /workspaces/TPCFLU
