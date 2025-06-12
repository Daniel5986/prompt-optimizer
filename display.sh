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

echo "📦 [部署开始] 项目: $APP_NAME"
echo "📁 新版本目录: $NEW_RELEASE_DIR"

# ----------------------
# 1. 创建新版本目录
# ----------------------
mkdir -p "$NEW_RELEASE_DIR"

# ----------------------
# 2. 拷贝源码
# ----------------------
echo "📂 正在复制源码到 $NEW_RELEASE_DIR"
cp -r ./ "$NEW_RELEASE_DIR"

# ----------------------
# 3. 安装依赖
# ----------------------
cd "$NEW_RELEASE_DIR"
echo "📦 安装依赖（使用 pnpm workspace）..."
pnpm install --frozen-lockfile

# ----------------------
# 4. 拷贝环境变量
# ----------------------
if [ -f "$BASE_DIR/.env.production.local" ]; then
  cp "$BASE_DIR/.env.production.local" "$WEB_DIR/.env.production.local"
  echo "✅ 已复制 .env.production.local 到 packages/web/"
else
  echo "⚠️ 未找到 $BASE_DIR/.env.production.local，构建可能缺失关键变量"
fi

# ----------------------
# 5. 构建项目
# ----------------------
echo "🛠️ 开始构建 packages/web..."
cd "$WEB_DIR"
pnpm build

# ----------------------
# 6. 检查构建结果
# ----------------------
if [ ! -f "$WEB_DIST/index.html" ]; then
  echo "❌ 构建失败：未找到 dist/index.html"
  exit 1
fi

# ----------------------
# 7. 验证关键变量注入
# ----------------------
echo "🔍 检查是否注入 API Key..."
grep -q 'sk-' "$WEB_DIST/assets/"*.js && echo "✅ API Key 已写入构建产物" || echo "⚠️ 未检测到 API Key，请确认 .env 文件注入是否成功"

# ----------------------
# 8. 更新 current 软链
# ----------------------
echo "🔗 更新 current -> $WEB_DIST"
ln -sfn "$WEB_DIST" "$CURRENT_LINK"

# ----------------------
# 9. 启动或重启 PM2 服务
# ----------------------
echo "🚀 使用 serve + pm2 启动服务（端口 3000）"
pm2 delete "$APP_NAME" || true
pm2 start "$(pnpm bin)/serve -s $CURRENT_LINK -l 3000" --name "$APP_NAME"

# ----------------------
# 10. 清理旧版本（保留最近 3 个）
# ----------------------
cd "$RELEASE_DIR"
KEEP=3
echo "🧹 清理旧版本（保留最近 $KEEP 个）"
ls -dt */ | tail -n +$((KEEP + 1)) | xargs rm -rf || true

echo "✅ 部署完成！服务地址：http://localhost:3000"
