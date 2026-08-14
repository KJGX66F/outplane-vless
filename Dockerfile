FROM alpine:3.22

ARG XRAY_VERSION=26.7.28
ARG CLOUDFLARED_VERSION=2026.8.1

RUN apk add --no-cache \
    ca-certificates \
    curl \
    unzip

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
        x86_64) \
            XRAY_ARCH="64"; \
            CF_ARCH="amd64" \
            ;; \
        aarch64|arm64) \
            XRAY_ARCH="arm64-v8a"; \
            CF_ARCH="arm64" \
            ;; \
        *) \
            echo "Unsupported architecture: ${ARCH}"; \
            exit 1 \
            ;; \
    esac; \
    curl -fL \
      "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip" \
      -o /tmp/xray.zip; \
    unzip -j /tmp/xray.zip xray -d /usr/local/bin/; \
    chmod +x /usr/local/bin/xray; \
    curl -fL \
      "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${CF_ARCH}" \
      -o /usr/local/bin/cloudflared; \
    chmod +x /usr/local/bin/cloudflared; \
    rm -f /tmp/xray.zip

COPY start.sh /start.sh

RUN chmod +x /start.sh \
    && mkdir -p /etc/xray

ENV PORT=8080
ENV WS_PATH=/ws

EXPOSE 8080

CMD ["/start.sh"]
