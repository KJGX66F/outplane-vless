#!/bin/sh

set -eu

PORT="${PORT:-8080}"
WS_PATH="${WS_PATH:-/ws}"

# 确保 WS_PATH 以 / 开头
case "$WS_PATH" in
    /*) ;;
    *) WS_PATH="/$WS_PATH" ;;
esac

# 如果没有设置 UUID，就自动生成一个
if [ -z "${UUID:-}" ]; then
    UUID="$(xray uuid)"
fi

echo ""
echo "=========================================="
echo "        OutPlane VLESS + CF Tunnel"
echo "=========================================="
echo ""
echo "UUID: ${UUID}"
echo "PORT: ${PORT}"
echo "WS PATH: ${WS_PATH}"
echo ""

cat > /etc/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },

  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${PORT},
      "protocol": "vless",

      "settings": {
        "users": [
          {
            "id": "${UUID}"
          }
        ],

        "decryption": "none"
      },

      "streamSettings": {
        "method": "websocket",
        "security": "none",

        "wsSettings": {
          "path": "${WS_PATH}"
        }
      }
    }
  ],

  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

echo "Starting Xray..."

xray run -c /etc/xray/config.json &

XRAY_PID=$!

sleep 2

echo ""
echo "Starting Cloudflare Quick Tunnel..."
echo ""

rm -f /tmp/cloudflared.log

cloudflared tunnel \
    --no-autoupdate \
    --url "http://127.0.0.1:${PORT}" \
    2>&1 | tee /tmp/cloudflared.log &

CF_PID=$!

echo ""
echo "Waiting for Cloudflare Tunnel..."
echo ""

TUNNEL_HOST=""

i=0

while [ "$i" -lt 60 ]; do

    TUNNEL_URL="$(grep -oE 'https://[A-Za-z0-9.-]+\.trycloudflare\.com' /tmp/cloudflared.log 2>/dev/null | head -n 1 || true)"

    if [ -n "$TUNNEL_URL" ]; then

        TUNNEL_HOST="$(echo "$TUNNEL_URL" | sed 's#https://##')"

        break

    fi

    sleep 1

    i=$((i + 1))

done

echo ""
echo "=========================================="

if [ -n "$TUNNEL_HOST" ]; then

    echo ""
    echo "Cloudflare Tunnel created successfully!"
    echo ""
    echo "Host:"
    echo "${TUNNEL_HOST}"
    echo ""
    echo "Port:"
    echo "443"
    echo ""
    echo "UUID:"
    echo "${UUID}"
    echo ""
    echo "Transport:"
    echo "WebSocket"
    echo ""
    echo "Path:"
    echo "${WS_PATH}"
    echo ""
    echo "TLS:"
    echo "true"
    echo ""

    ENCODED_PATH="$(echo "${WS_PATH}" | sed 's#/#%2F#g')"

    VLESS_LINK="vless://${UUID}@${TUNNEL_HOST}:443?encryption=none&security=tls&sni=${TUNNEL_HOST}&type=ws&host=${TUNNEL_HOST}&path=${ENCODED_PATH}#OutPlane-CF"

    echo "=========================================="
    echo ""
    echo "VLESS LINK:"
    echo ""
    echo "${VLESS_LINK}"
    echo ""
    echo "=========================================="

else

    echo ""
    echo "Cloudflare tunnel hostname not detected."
    echo ""
    echo "Please check cloudflared logs."
    echo ""

fi

# 保持两个进程运行
while true; do

    if ! kill -0 "${XRAY_PID}" 2>/dev/null; then
        echo "Xray stopped."
        exit 1
    fi

    if ! kill -0 "${CF_PID}" 2>/dev/null; then
        echo "cloudflared stopped."
        exit 1
    fi

    sleep 30

done
