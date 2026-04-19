FROM --platform=linux/arm64 alpine:latest

ENV OPENCODE_HOME=/opt/opencode
ARG OPENCODE_REF=dev

RUN apk add --no-cache \
    aws-cli \
    bash \
    curl \
    git \
    github-cli \
    jq \
    nodejs \
    npm \
    python3

RUN git clone --depth 1 --branch "${OPENCODE_REF}" https://github.com/anomalyco/opencode.git "${OPENCODE_HOME}" \
    && cd "${OPENCODE_HOME}" \
    && npm install \
    && npm install -g .

COPY docker/entrypoint.sh /usr/local/bin/opencode-entrypoint
RUN chmod +x /usr/local/bin/opencode-entrypoint

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/opencode-entrypoint"]
CMD ["opencode"]
