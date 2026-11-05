#!/bin/bash
# Apply the preconfig overlay into a mounted rootfs, injecting secrets from the
# builder's local file (default: /root/e5/secrets/preconfig.env, never committed).
#   apply-preconfig.sh MNT [SECRETS_FILE]
# MNT: the mounted rootfs (e.g. /root/e5/pkg/mnt)
set -euo pipefail
MNT=${1:?mounted rootfs 必填}
SECRETS=${2:-/root/e5/secrets/preconfig.env}
HERE=$(cd "$(dirname "$0")/.." && pwd)

[ -d "$MNT" ] || { echo "no rootfs: $MNT"; exit 1; }
[ -f "$SECRETS" ] || { echo "缺少 secrets: $SECRETS（复制 build/preconfig-secrets.example 并填写）"; exit 1; }

# load secrets (WIFI_KEY, ZT_NETWORK, ROOT_PASSWORD, DASHBOARD_PASSWORD)
. "$SECRETS"
: "${WIFI_KEY:?}${ZT_NETWORK:?}${ROOT_PASSWORD:?}"
DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD:-openclash}

# 1. copy the preconfig overlay (uci-defaults template) into the rootfs
cp -a "$HERE/preconfig-overlay/." "$MNT/"
chmod 755 "$MNT/etc/uci-defaults/95-e5-preconfig"

# 2. inject secrets (placeholder -> real values)
S="$MNT/etc/uci-defaults/95-e5-preconfig"
sed -i "s/__WIFI_KEY__/$WIFI_KEY/g; s/__ZT_NETWORK__/$ZT_NETWORK/g; s/__ROOT_PASSWORD__/$ROOT_PASSWORD/g; s/__DASHBOARD_PASSWORD__/$DASHBOARD_PASSWORD/g" "$S"

# 3. verify no placeholder remains
if grep -q '__[A-Z_]*__' "$S"; then
  echo "警告: uci-defaults 仍有未替换占位符:"; grep -o '__[A-Z_]*__' "$S" | sort -u
fi

echo "preconfig: applied to $MNT (secrets from $SECRETS)"
