#!/usr/bin/env bash
# 使用 curl 调用 /api/analyze，传入本地图片的 Base64 和意图。
# 用法: ./call_analyze.sh [图片路径] [意图]
# 示例: ./call_analyze.sh ~/Desktop/photo.jpg "赛博朋克雨夜街景"

set -e
IMAGE_PATH="${1:-}"
INTENT="${2:-赛博朋克风格的雨夜街景}"
API_URL="${API_URL:-http://127.0.0.1:8000}"

if [[ -z "$IMAGE_PATH" || ! -f "$IMAGE_PATH" ]]; then
  echo "用法: $0 <图片路径> [意图]"
  echo "示例: $0 ~/Desktop/photo.jpg \"赛博朋克雨夜街景\""
  exit 1
fi

echo "图片: $IMAGE_PATH"
echo "意图: $INTENT"
echo "编码为 Base64..."
B64_FILE=$(mktemp)
base64 -i "$IMAGE_PATH" | tr -d '\n' > "$B64_FILE"

echo "构建请求体..."
REQ_FILE=$(mktemp)
jq -n --rawfile b64 "$B64_FILE" --arg intent "$INTENT" '{image_base64: $b64, intent: $intent}' > "$REQ_FILE"
rm -f "$B64_FILE"

echo "发送 POST $API_URL/api/analyze ..."
HTTP_OUT=$(mktemp)
HTTP_BODY=$(mktemp)
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$HTTP_BODY" -X POST "$API_URL/api/analyze" \
  -H "Content-Type: application/json" \
  -d @"$REQ_FILE" \
  -D "$HTTP_OUT")
rm -f "$REQ_FILE"

echo "HTTP 状态: $HTTP_CODE"
if [[ -s "$HTTP_OUT" ]]; then
  echo "响应头 (含 X-Response-Time-Seconds):"
  cat "$HTTP_OUT"
fi
echo "响应体:"
cat "$HTTP_BODY" | jq . 2>/dev/null || cat "$HTTP_BODY"
rm -f "$HTTP_OUT" "$HTTP_BODY"

if [[ "$HTTP_CODE" -ge 400 ]]; then
  exit 1
fi
