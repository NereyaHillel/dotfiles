#!/data/data/com.termux/files/usr/bin/sh
SHIM_PATH="$HOME/.config/nvim/copilot-shim.js"
if [ -d "/data/data/com.termux" ]; then
    exec /data/data/com.termux/files/usr/bin/node --require "$SHIM_PATH" "$@"
else
    exec node "$@"
fi
