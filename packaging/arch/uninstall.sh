#!/usr/bin/env bash
# Undo packaging/arch/install.sh.
#   sudo bash packaging/arch/uninstall.sh            keep enrolled prints
#   sudo bash packaging/arch/uninstall.sh --purge    also delete /var/lib/fingerprint-ocv
# The fprintd package stays installed (remove it with pacman if you like).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }

PAM_FILE=/etc/pam.d/sudo
if grep -q "# fingerprint-ocv" "$PAM_FILE"; then
    sed -i '/# fingerprint-ocv$/d' "$PAM_FILE"
    echo "removed the fingerprint line from $PAM_FILE"
fi
rm -f "$PAM_FILE.bak-fingerprint-ocv"

systemctl disable --now fprintd.service 2>/dev/null || true
rm -f /etc/systemd/system/fprintd.service /usr/local/bin/fingerprint-ocv
systemctl daemon-reload
[ "${1:-}" = "--purge" ] && rm -rf /var/lib/fingerprint-ocv && echo "deleted enrolled prints"
echo "fingerprint-ocv removed"
