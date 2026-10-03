#!/usr/bin/env bash
# Install fingerprint-ocv as the system fingerprint daemon on Arch Linux.
#
#   sudo bash packaging/arch/install.sh          daemon only (then enroll: fprintd-enroll)
#   sudo bash packaging/arch/install.sh --pam    also let sudo accept a fingerprint
#
# Build first (as your user):  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build
# Undo everything:             sudo bash packaging/arch/uninstall.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="$ROOT/build/src/fingerprint-ocv"
PAM_FILE=/etc/pam.d/sudo
PAM_LINE="auth       sufficient   pam_fprintd.so max-tries=2 timeout=10  # fingerprint-ocv"

[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }
[ -x "$BIN" ] || { echo "build first: $BIN not found" >&2; exit 1; }

# fprintd provides pam_fprintd.so, the fprintd-* clients and the D-Bus policy for
# net.reactivated.Fprint; its own daemon is replaced by the unit below
pacman -S --needed --noconfirm fprintd

install -Dm755 "$BIN" /usr/local/bin/fingerprint-ocv
install -Dm644 "$HERE/fprintd.service" /etc/systemd/system/fprintd.service
systemctl daemon-reload
# started at boot and kept running (see the unit); restart picks up a new binary
systemctl enable fprintd.service
systemctl restart fprintd.service
# stopped before suspend and started fresh after resume (the reader is reset on resume)
install -Dm755 "$HERE/fingerprint-ocv.sleep" /usr/lib/systemd/system-sleep/fingerprint-ocv
echo "daemon installed and running: /usr/local/bin/fingerprint-ocv (unit /etc/systemd/system/fprintd.service)"

if [ "${1:-}" = "--pam" ]; then
    if ! grep -q "pam_fprintd.so" "$PAM_FILE"; then
        cp -n "$PAM_FILE" "$PAM_FILE.bak-fingerprint-ocv"
        # first auth line: a fingerprint is enough, otherwise fall through to the password
        awk -v line="$PAM_LINE" 'done == 0 && /^auth/ { print line; done = 1 } { print }' \
            "$PAM_FILE" > "$PAM_FILE.new"
        mv "$PAM_FILE.new" "$PAM_FILE"
    fi
    echo "sudo now asks for a fingerprint first (2 tries, 10 s each), then the password"
fi
