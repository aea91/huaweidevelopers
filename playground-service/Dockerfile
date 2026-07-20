FROM ubuntu:20.04 AS ark-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      ccache \
      curl \
      g++-multilib \
      gcc-multilib \
      git \
      git-lfs \
      libc++1 \
      make \
      nodejs \
      npm \
      perl \
      python-is-python3 \
      python3 \
      python3-pip \
      ruby \
      unzip \
      xz-utils \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://gitee.com/oschina/repo/raw/fork_flow/repo-py3 \
      -o /usr/local/bin/repo \
    && chmod +x /usr/local/bin/repo \
    && pip3 install --no-cache-dir requests

WORKDIR /ark-source

RUN repo init -u https://gitee.com/ark-standalone-build/manifest.git -b master \
    && repo sync -c -j8 \
    && repo forall -c 'git lfs pull'

RUN ./prebuilts_download.sh \
    && python3 ark.py x64.release es2panda ark_js_vm

RUN mkdir -p /ark-package/bin /ark-package/lib \
    && cp out/x64.release/arkcompiler/ets_frontend/es2abc /ark-package/bin/ \
    && cp out/x64.release/arkcompiler/ets_runtime/ark_js_vm /ark-package/bin/ \
    && find out/x64.release -type f \( -name '*.so' -o -name '*.so.*' \) \
      -exec cp -Lf {} /ark-package/lib/ \; \
    && chmod 0755 /ark-package/bin/es2abc /ark-package/bin/ark_js_vm

FROM node:20-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu72 zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 playground

WORKDIR /app

COPY package.json server.js ./
COPY --from=ark-builder /ark-package/ /opt/ark/

RUN test -x /opt/ark/bin/es2abc \
    && test -x /opt/ark/bin/ark_js_vm \
    && chown -R playground:playground /app /opt/ark

USER playground

ENV PORT=8080 \
    NODE_ENV=production \
    ARK_COMPILER_PATH=/opt/ark/bin/es2abc \
    ARK_RUNTIME_PATH=/opt/ark/bin/ark_js_vm \
    ARK_LIBRARY_PATH=/opt/ark/lib \
    PROCESS_TIMEOUT_MS=5000 \
    MAX_SOURCE_BYTES=65536 \
    MAX_CONCURRENT_RUNS=2

EXPOSE 8080

CMD ["node", "server.js"]
