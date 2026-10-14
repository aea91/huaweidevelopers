# The ArkCompiler toolchain is copied from a pinned image instead of being built
# here (see Dockerfile.toolchain). The default is the image deployed on
# 2026-07-17, also tagged ark-toolchain-20260717. Compiler and runtime must
# come from the same OpenHarmony build, so replace both together.
ARG ARK_TOOLCHAIN_IMAGE=europe-west1-docker.pkg.dev/arkuibuilder/arkuibuild/playground@sha256:763c77bc8a635e8d51bb683af44495f2ff92b1cb0ced5aea8f9d63fffb5a0166

FROM ${ARK_TOOLCHAIN_IMAGE} AS ark-toolchain

FROM node:20-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu72 zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 playground

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY server.js arkts-check.js ./
COPY --from=ark-toolchain /opt/ark/ /opt/ark/

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
