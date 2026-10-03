
## USB fingerprint sensor driver

Supported device: FPC Sensor Controller L:0001 FW:021.26.2.x (10a5:9201)

## Arch Linux (this fork)

This fork builds against current Arch Linux packages and installs the daemon as the
system's fprintd, so the standard tools work with the FPC 10a5:9201 reader of the
RedmiBook Pro 15 2022 and similar Xiaomi laptops: `fprintd-enroll`, `fprintd-verify`
and `pam_fprintd` (e.g. a fingerprint for `sudo`).

Changes against upstream:

- builds without vcpkg (system packages) and with OpenCV 5 (renamed modules);
- jinx: fixes the release build with GCC 15 (the submodule points at a fork branch);
- emits `VerifyFingerSelected`, so pam_fprintd shows its "Place your finger on ..."
  prompt, and names the device "the power button fingerprint reader";
- `packaging/arch/`: a hardened systemd unit installed as `fprintd.service`, an install
  script with an optional sudo PAM step, and an uninstall script.

```sh
sudo pacman -S --needed base-devel cmake libusb libevent openssl opencv
git clone https://github.com/Capofret2/fingerprint-ocv
cd fingerprint-ocv
git submodule update --init asyncdbus asyncusb jinx   # vcpkg is not needed
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

sudo bash packaging/arch/install.sh        # daemon (pulls in fprintd for PAM and the clients)
fprintd-enroll -f right-index-finger       # one run per finger: right-thumb, left-index-finger, ...
fprintd-verify
sudo bash packaging/arch/install.sh --pam  # sudo: fingerprint first (2 tries, 10 s), then password
```

`sudo bash packaging/arch/uninstall.sh` reverts everything (add `--purge` to delete the
enrolled prints). Enrolling stitches small captures of the fingertip together: lift the
finger completely between touches and vary the position, or verification will only work
for the part of the finger you happened to press.

Matching is an OpenCV image comparison on the host, not the vendor's algorithm: good for
convenience, not a strong security barrier. The password always remains as a fallback.

## Environment

Ubuntu: `apt install -y --no-install-recommends libusb-1.0-0-dev libevent-dev libdbus-1-dev libssl-dev libopencv-dev make cmake pkg-config gcc g++`

Archlinux: `pacman --noconfirm -S libusb libevent libdbus openssl libopencv-dev make cmake pkg-config gcc`

## Build

```bash
git clone https://github.com/vrolife/fingerprint-ocv
cd fingerprint-ocv
git submodule init
git submodule update
cmake -S . -B build
cmake --build build
cp build/src/fingerprint-ocv /path/to/somewhere
```

## Install && Binary

[Link](https://github.com/vrolife/modern_laptop/tree/main/drivers/fingerprint)
