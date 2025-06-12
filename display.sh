#!/bin/bash

set -e

# ----------------------
# 配置参数
# ----------------------
APP_NAME="prompt-optimizer"
BASE_DIR="/home/syj88668/display/$APP_NAME"
RELEASE_DIR="$BASE_DIR/releases"
CURRENT_LINK="$BASE_DIR/current"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NEW_RELEASE_DIR="$RELEASE_DIR/$TIMESTAMP"
WEB_DIR="$NEW_RELEASE_DIR/packages/web"
WEB_DIST="$WEB_DIR/dist"
LOG_FILE="$BASE_DIR/deploy.log"

# ----------------------
# 开始部署
# ----------------------
echo "📦 [部署开始] 项目: $APP_NAME" | tee -a "$LOG_FILE"
echo "📁 新版本目录: $NEW_RELEASE_DIR" | tee -a "$LOG_FILE"

mkdir -p "$NEW_RELEASE_DIR"

echo "📂 正在复制源码..." | tee -a "$LOG_FILE"
cp -r ./ "$NEW_RELEASE_DIR"

cd "$NEW_RELEASE_DIR"
echo "📦 安装依赖..." | tee -a "$LOG_FILE"
pnpm install --frozen-lockfile | tee -a "$LOG_FILE"

# ----------------------
# 环境变量处理
# ----------------------
ENV_FILE_SRC="$BASE_DIR/.env.production.local"
ENV_FILE_DEST="$WEB_DIR/.env.production.local"
if [ -f "$ENV_FILE_SRC" ]; then
  cp "$ENV_FILE_SRC" "$ENV_FILE_DEST"
  echo "✅ 已复制 .env.production.local 到构建目录" | tee -a "$LOG_FILE"
else
  echo "⚠️ 警告：未找到 .env.production.local，变量可能未生效" | tee -a "$LOG_FILE"
fi

# ----------------------
# 构建
# ----------------------
cd "$WEB_DIR"
echo "🛠️ 开始构建..." | tee -a "$LOG_FILE"
pnpm build | tee -a "$LOG_FILE"

if [ ! -f "$WEB_DIST/index.html" ]; then
  echo "❌ 构建失败，未生成 dist/index.html" | tee -a "$LOG_FILE"
  exit 1
fi

# ----------------------
# 检查关键变量注入
# ----------------------
echo "🔍 检查是否注入 API Key..." | tee -a "$LOG_FILE"
if grep -q 'sk-' "$WEB_DIST/assets/"*.js; then
  echo "✅ API Key 已写入构建产物" | tee -a "$LOG_FILE"
else
  echo "⚠️ 未检测到 API Key，请确认变量配置和使用" | tee -a "$LOG_FILE"
fi

# ----------------------
# 切换软链
# ----------------------
echo "🔗 更新软链 current -> $WEB_DIST" | tee -a "$LOG_FILE"
ln -sfn "$WEB_DIST" "$CURRENT_LINK"

# ----------------------
# PM2 启动 serve
# ----------------------
echo "🚀 使用 serve + pm2 启动服务（端口 3000）" | tee -a "$LOG_FILE"

if ! command -v serve &> /dev/null; then
  echo "❌ 错误：serve 未安装，请先执行 pnpm add -g serve" | tee -a "$LOG_FILE"
  exit 1
fi

pm2 delete "$APP_NAME" || true

pm2 start --name "$APP_NAME" -- bash -c "serve -s $CURRENT_LINK -l 3000" | tee -a "$LOG_FILE"

# ----------------------
# 清理旧版本
# ----------------------
cd "$RELEASE_DIR"
KEEP=3
echo "🧹 清理旧版本（仅保留最近 $KEEP 个）" | tee -a "$LOG_FILE"
ls -dt */ | tail -n +$((KEEP + 1)) | xargs rm -rf || true

# ----------------------
# 完成提示
# ----------------------
echo "✅ 部署完成！访问地址：http://localhost:3000" | tee -a "$LOG_FILE"
echo "📄 日志位置：$LOG_FILE"
