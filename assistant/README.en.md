# Space Assistant

[中文](README.md) · English

A desktop program for Mac and Windows that connects to the reMarkable over USB and installs Space together
with the base layer it depends on in one go.

Pure-Go SSH direct connection: no server, nothing is uploaded. Every command run on the device and every
file written is recorded in a local audit log (the UI has an "Open log directory" button).

## What it installs

**Base layer (only touched when a system upgrade forces a change)** — the source lives in `base/` in this
repo (formerly rmkit-cn): xovi, the qmldiff injection chain plus hashtab, the runtime-injected `.so`, the
Simplified Chinese `.qm`, and the IME backend. **This is the part that can actually brick the device**:
when the hashtab does not match the firmware you get a qmldiff panic → xochitl crash → A/B rollback. So
on-device installs use the same six-phase anti-brick script path as `install.sh`, run verbatim with not a
single line changed.

**Space** — the shell, the built-in apps, and the backend `space-server` (which replaces the retired
upload-server and also listens on 8080). Space uses `Qt.createComponent` for async loading, so a broken
QML file only means the panel will not open — it will not crash xochitl.

After installation, the sidebar's "Advanced" entry becomes "Space" — the switch is driven by the marker
file `/home/root/rmkit-cn/space/.primary`, and the injection library checks for both that file and
`Space.qml`. If either is missing it falls back to showing "Advanced".

The assistant also installs the single-slot Android for Paper Pro Move (unchanged from before).

## Usage

```sh
# 1. Build the backend binary from the repo root first
cd .. && make all

# 2. Build the install bundle (base artifacts come from ../base/dist, see base/README.md)
cd assistant && make bundle

# 3. Build the UI
make build-mac          # or make build-win
open build/bin/space-assistant.app
```

## Command line

Same core, no GUI — for CI and remote troubleshooting:

```sh
make cli
dist/assistant-cli-darwin-arm64 -host 10.11.99.1 -password xxx probe
dist/assistant-cli-darwin-arm64 ... -bundle dist/space-bundle.zip plan-rmkit   # preview
dist/assistant-cli-darwin-arm64 ... -bundle dist/space-bundle.zip run-rmkit    # install

# No device attached — fake the probe result and compute the plan. Useful for self-checking install logic.
dist/assistant-cli-darwin-arm64 -bundle dist/space-bundle.zip -arch armv7l -model rm2 plan-offline
```

## Things that must not change

- **Device data paths stay at `~/.local/share/rmkit-cn/`.** Fonts, lock-screen images, installed apps and
  app data all live there — renaming it is the same as making user data silently disappear.
- **The Space shell stays at `/home/root/rmkit-cn/space/`.** The path is hardcoded in the injection
  library (`qml_inject_impl.cpp`); changing it means rebuilding `.so` files for both architectures.
- **`/etc` is a tmpfs overlay.** systemd unit files and `wants` symlinks must be written to both the
  upper (ext4) and lower layers — writing only to `/etc` loses the change on reboot. `systemctl enable`
  symlinks have the same problem, which is why the scripts create them by hand.
- **Transfers use `--no-same-owner`.** Without it, tar restores the build host's uid (502) onto the
  device; once the owner of `/home/root` changes, sshd and xochitl both lock up. **Never**
  `chown -R /home/root` either: the single-slot Android system and `/data` sit under it.
- **After upload, verify the backend binary can execute** before touching services. A wrong architecture
  only shows up at runtime as "Exec format error", which is too late once the six-phase run completes —
  by then the old service is masked and upload / fonts / Bluetooth / AI will all fail together.
