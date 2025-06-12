#!/bin/bash

set -e

# ----------------------
# 配置参数
# ----------------------
APP_NAME="prompt-optimizer"
PORT=3000
BASE_DIR="/home/syj88668/display/$APP_NAME"
RELEASE_DIR="$BASE_DIR/releases"
CURRENT_LINK="$BASE_DIR/current"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NEW_RELEASE_DIR="$RELEASE_DIR/$TIMESTAMP"
WEB_DIR="$NEW_RELEASE_DIR/packages/web"
WEB_DIST="$WEB_DIR/dist"
LOG_FILE="$BASE_DIR/deploy.log"

# ----------------------
# 日志函数
# ----------------------
log() {
  echo -e "$1" | tee -a "$LOG_FILE"
}

log "📦 [部署开始] 项目: $APP_NAME"
log "📁 新版本目录: $NEW_RELEASE_DIR"

# ----------------------
# 1. 创建发布目录
# ----------------------
mkdir -p "$NEW_RELEASE_DIR"

# ----------------------
# 2. 拷贝源码
# ----------------------
log "📂 正在复制源码..."
cp -r ./ "$NEW_RELEASE_DIR"

# ----------------------
# 3. 安装依赖
# ----------------------
cd "$NEW_RELEASE_DIR"
log "📦 安装依赖..."
pnpm install --frozen-lockfile || log "⚠️ 依赖安装失败，请检查"

# ----------------------
# 4. 拷贝环境变量
# ----------------------
if [ -f "$BASE_DIR/.env.production.local" ]; then
  cp "$BASE_DIR/.env.production.local" "$WEB_DIR/.env.production.local"
  log "✅ 已复制 .env.production.local"
else
  log "⚠️ 警告：未找到 .env.production.local，变量可能未生效"
fi

# ----------------------
# 5. 构建
# ----------------------
cd "$WEB_DIR"
log "🛠️ 开始构建..."
pnpm build

# ----------------------
# 6. 检查构建结果
# ----------------------
if [ ! -f "$WEB_DIST/index.html" ]; then
  log "❌ 构建失败：未生成 index.html"
  exit 1
fi

# ----------------------
# 7. 检查是否注入关键变量
# ----------------------
log "🔍 检查是否注入 API Key..."
grep -q 'sk-' "$WEB_DIST/assets/"*.js && \
  log "✅ API Key 已写入构建产物" || \
  log "⚠️ 未检测到 API Key，请确认 .env 是否生效"

# ----------------------
# 8. 更新软链
# ----------------------
log "🔗 更新软链 current -> $WEB_DIST"
ln -sfn "$WEB_DIST" "$CURRENT_LINK"

# ----------------------
# 9. 重启 PM2 服务
# ----------------------
log "🚀 使用 serve + pm2 启动服务（端口 $PORT）"
pm2 delete "$APP_NAME" >/dev/null 2>&1 || log "ℹ️ 无需删除旧进程（未找到）"

pm2 start --name "$APP_NAME" -- bash -c "serve -s $CURRENT_LINK -l $PORT"
log "✅ PM2 启动完成（http://localhost:$PORT）"

# ----------------------
# 10. 清理旧版本
# ----------------------
log "🧹 清理旧版本（仅保留最近 3 个）"
cd "$RELEASE_DIR"
ls -dt */ | tail -n +4 | xargs rm -rf || log "⚠️ 清理旧版本失败，但不影响部署"

log "✅ 部署完成！"
log "📄 日志记录位置：$LOG_FILE"
