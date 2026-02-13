# AI Photo Director – Backend (Phase 1.1)

FastAPI 中继：接收 Base64 图片 + 用户意图，调用 CharaBoard 多模态 API，返回 Shader 参数与语音指导。

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `CHARABOARD_API_KEY` | 是 | CharaBoard API Key |
| `CHARABOARD_BASE_URL` | 否 | 默认 `https://api-chat.charaboard.com/v2/` |
| `GPT_TYPE` | 否 | 默认 `8602`（MiniMax M2.1），需为支持视觉的模型 |
| `X_APP_ID` | 否 | 默认 `4` |
| `X_PLATFORM_ID` | 否 | 默认 `5` |
| `X_MAX_TIME` | 否 | 模型最大回复超时（秒），默认 `30` |
| `X_QUALITY` | 否 | 路由策略：`speed`（速度优先）、`cost`（成本优先），默认 `speed` |

## 安装与运行

**方式一：使用虚拟环境（推荐）**

```bash
cd backend
python3 -m venv venv
source venv/bin/activate   # macOS/Linux 激活后命令行前会显示 (venv)
pip install -r requirements.txt
export CHARABOARD_API_KEY=your-api-key
uvicorn main:app --reload
```

未激活时系统可能没有 `pip` 命令，需先执行 `source venv/bin/activate` 再装依赖。

**方式二：不激活 venv，直接用 venv 里的 pip**

```bash
cd backend
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
export CHARABOARD_API_KEY=your-api-key
./venv/bin/uvicorn main:app --reload
```

服务默认: `http://127.0.0.1:8000`。

## 接口

### GET /health

检查服务与 API Key 是否配置。

### POST /api/analyze

**Request body (JSON):**

```json
{
  "image_base64": "<base64 字符串，或 data:image/jpeg;base64,...>",
  "intent": "赛博朋克风格的雨夜街景"
}
```

**Response:** 与 AI 约定格式一致：

```json
{
  "analysis": {
    "light_direction": "string",
    "subject_mood": "string",
    "composition_tip": "string"
  },
  "shader": {
    "brightness": 0,
    "saturation": 1.0,
    "contrast": 0,
    "tintR": 1.0,
    "tintG": 1.0,
    "tintB": 1.0,
    "warmth": 0,
    "vignette": 0
  },
  "voice_guide": "镜头往左移一点",
  "ready_to_capture": false
}
```

**响应头:** `X-Response-Time-Seconds` 为本次推理耗时（秒），用于 Phase 1.1 延迟测试。

**响应延迟优化（目标 < 2s）**：若延迟 > 3s，可尝试：1）图片缩放到 640px 宽；2）已默认 `X_QUALITY=speed`；3）已调低 `max_tokens`；4）若 CharaBoard 提供更轻量视觉模型，可改 `GPT_TYPE`。

## Phase 1.1 延迟测试（curl）

接口需要两个参数：**图片的 Base64 字符串**、**意图文本**。下面两种方式任选其一。

---

### 方式一：用脚本一键调用（推荐）

已提供脚本，只需传**图片路径**和**意图**即可：

```bash
cd backend
chmod +x scripts/call_analyze.sh
./scripts/call_analyze.sh /path/to/your/photo.jpg "赛博朋克雨夜街景"
```

脚本会：把图片转成 Base64 → 拼成 JSON → 发 POST → 打印响应头和 JSON。  
需要本机已安装 `jq`（`brew install jq`）。

---

### 方式二：手把手用 curl 传一张图

**步骤 1：准备一张图片**

- 任意一张 `.jpg` / `.jpeg`（如手机拍的、或从网上下载的测试图）。
- 建议先缩小到宽度约 640px，体积更小、请求更快（可用预览/Photoshop/在线工具缩小）。

**步骤 2：把图片转成 Base64 并写入文件**

- Base64 是一串字符，表示这张图的二进制内容，接口要求传这个字符串。
- 在终端执行（把 `~/Desktop/photo.jpg` 换成你的图片路径）：

```bash
base64 -i ~/Desktop/photo.jpg | tr -d '\n' > /tmp/img_b64.txt
```

- 说明：`base64 -i 文件` 输出该文件的 Base64；`tr -d '\n'` 去掉换行，得到一整行；结果保存在 `/tmp/img_b64.txt`。

**步骤 3：用 jq 拼成请求体 JSON**

- 请求体必须是：`{"image_base64": "上面那串Base64", "intent": "你的拍摄意图"}`。
- 用 jq 可以安全地把长字符串放进 JSON（避免手写引号、转义出错）：

```bash
jq -n \
  --rawfile b64 /tmp/img_b64.txt \
  --arg intent "赛博朋克雨夜街景" \
  '{image_base64: $b64, intent: $intent}' \
  > /tmp/request.json
```

- 若未安装 jq：`brew install jq`（macOS）。

**步骤 4：用 curl 发 POST 请求**

- 用上面生成的 `request.json` 作为 body，调用本地服务：

```bash
curl -s -X POST "http://127.0.0.1:8000/api/analyze" \
  -H "Content-Type: application/json" \
  -d @/tmp/request.json \
  -D /tmp/headers.txt \
  -o /tmp/body.json
```

- 说明：
  - `-d @/tmp/request.json`：请求体从文件读取（@ 表示从文件读）。
  - `-D /tmp/headers.txt`：把响应头保存到文件。
  - `-o /tmp/body.json`：把响应体保存到文件。

**步骤 5：看结果和延迟**

```bash
# 看响应头里的推理耗时（秒）
grep -i x-response-time /tmp/headers.txt

# 看返回的 JSON（分析结果、shader 参数、语音指导等）
cat /tmp/body.json | jq .
```

响应头里的 `X-Response-Time-Seconds` 就是本次多模态推理的耗时，可用于 Phase 1.1 延迟测试。

## 多模态说明

当前请求按 OpenAI 兼容格式将图片放入 `messages[].content`：

- `content` 为数组，包含 `type: "text"` 与 `type: "image_url"`，`image_url.url` 为 `data:image/jpeg;base64,...`。

若 CharaBoard 使用不同格式，需在 `services/charaboard_client.py` 中调整 `_build_messages_with_image`。
