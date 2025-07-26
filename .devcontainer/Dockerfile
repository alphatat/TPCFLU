FROM mcr.microsoft.com/devcontainers/base:debian

# Set non-interactive frontend for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa \
  openjdk-17-jdk \
  clang cmake ninja-build pkg-config libgtk-3-dev \
  chromium \
  && apt-get clean

# Clone Flutter SDK and fix permissions
ENV FLUTTER_VERSION=3.22.1
RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
  && cd /opt/flutter \
  && git checkout $FLUTTER_VERSION \
  && chown -R vscode:vscode /opt/flutter \
  && git config --global --add safe.directory /opt/flutter

# Add Flutter and Dart to PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Accept Android licenses (optional, for Android builds)
RUN yes | /opt/flutter/bin/flutter doctor --android-licenses || true

# Pre-download Flutter dependencies and enable platforms
RUN /opt/flutter/bin/flutter precache --universal \
  && /opt/flutter/bin/flutter config --enable-linux-desktop --enable-web

# Set working directory
WORKDIR /workspaces/TPCFLU

# Run Flutter doctor to verify setup
RUN /opt/flutter/bin/flutter doctor