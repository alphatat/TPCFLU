FROM mcr.microsoft.com/devcontainers/dart:stable

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter \
    && /usr/local/flutter/bin/flutter doctor

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
