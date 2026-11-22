#!/usr/bin/env bash
# تثبيت OpenMotion محلياً وربطه بـ Claude Code
# المتطلبات: git, node >= 22.18, npm, ffmpeg, Chrome/Chromium
set -euo pipefail

INSTALL_DIR="${OPENMOTION_INSTALL_DIR:-$HOME/openmotion}"
DATA_DIR="${MOTION_DATA_DIR:-$HOME/openmotion-data}"

for bin in git node npm ffmpeg ffprobe; do
  command -v "$bin" >/dev/null || { echo "مفقود: $bin"; exit 1; }
done
node -e 'const [a,b]=process.versions.node.split(".").map(Number); if(a<22||(a===22&&b<18)){console.error("يلزم Node >= 22.18");process.exit(1)}'

mkdir -p "$DATA_DIR"
if [ ! -d "$INSTALL_DIR/.git" ]; then
  git -c filter.lfs.process= -c filter.lfs.smudge= -c filter.lfs.required=false \
    clone --depth 1 --single-branch --branch main \
    https://github.com/nexu-io/openmotion.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
npm ci
npm run build:studio

# ربط MCP مع Claude Code
if command -v claude >/dev/null; then
  claude mcp add openmotion --scope user \
    --env MOTION_DATA_DIR="$DATA_DIR" -- \
    "$(command -v node)" --experimental-strip-types "$INSTALL_DIR/mcp.ts" || true
fi

# تثبيت المهارة الرئيسية
npx --yes skills@1.9.0 add nexu-io/openmotion --skill openmotion --global --agent claude-code --copy --yes || true

echo
echo "تم. شغّل الواجهة بـ:  cd $INSTALL_DIR && MOTION_DATA_DIR=$DATA_DIR npm start"
echo "ثم افتح studioUrl الظاهر، وداخل Claude Code تحقق بـ /mcp"
