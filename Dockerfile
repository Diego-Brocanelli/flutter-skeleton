FROM ubuntu:22.04

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG FLUTTER_VERSION=stable

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Dependências de sistema: Flutter Linux Desktop + Android + SQLite
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip ca-certificates \
    clang cmake ninja-build pkg-config libgtk-3-dev \
    liblzma-dev libstdc++-12-dev \
    libsqlite3-dev sqlite3 \
    openjdk-17-jdk \
    usbutils android-tools-adb android-tools-fastboot \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} ${FLUTTER_HOME} \
    && git config --global --add safe.directory ${FLUTTER_HOME}

# Android SDK cmdline-tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl -sSL -o /tmp/cmdline-tools.zip \
        https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses > /dev/null || true \
    && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0"

# Usuário não-root espelhando UID/GID do host (evita problemas de permissão nos volumes)
RUN groupadd -g ${GROUP_ID} devuser \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash devuser \
    && usermod -aG sudo,plugdev devuser \
    && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/devuser/.local/share /home/devuser/.config /home/devuser/.cache \
    && chown -R devuser:devuser /home/devuser ${FLUTTER_HOME} ${ANDROID_SDK_ROOT}

USER devuser
WORKDIR /app

RUN flutter config --enable-linux-desktop --no-analytics \
    && flutter doctor -v || true

CMD ["bash"]