# Base layer

[中文](README.md) · English

The layer that wires Space into the reMarkable system: the xovi and qmldiff injection chain plus hashtab,
the runtime-injected `.so` (which is what puts the "Space" entry into the sidebar), the Simplified Chinese
`.qm` and keyboard layout `.rcc`, the IME backend, and the self-check and recovery scripts for after a
system upgrade. **All the brick-the-device risk lives here**, so this layer is only touched when a system
upgrade forces a change.

Migrated 2026-10-20 from [boangs/rmkit](https://github.com/boangs/rmkit) at `0f17826`; the commit history
before that stays in the old repo. The directory layout maps one-to-one onto the old repo, so relative
paths inside the scripts do not need to change; the on-device paths also stay the same
(`/home/root/rmkit-cn/...`, `~/.local/share/rmkit-cn/...`) — changing them would silently make user data
disappear.

| Directory | Contents |
|---|---|
| `intercept/` | `ime_hook.so` plus the runtime injection `qml-inject/` (thin hook + fat library) |
| `qmd-src/` `qmd/` | qmldiff patch sources, Simplified Chinese keyboard layout (the contents of `zh_CN.rcc`) |
| `installer/` | On-device scripts: `install.sh`, `precheck.sh` (fail-open), `fw-upgrade.sh`, `ota-watch.sh`, … |
| `systemd/` | xochitl drop-ins and OTA / IME services |
| `ime-go/` | Pure-Go IME backend (fallback engine for rm2) |
| `tools/` | `qmd-tool`, `create_rcc.go`, librime / Bluetooth audio cross-compile scripts, hashtab samples |
| `vendor/` | Prebuilt xovi and extensions, Bluetooth audio package |
| `scripts/` | Release checks (`check-dist.sh`, `lse_scan.py`), translation merge tools |
| `docs/` | Architecture, development, device matrix, upgrade SOP |

`installer/install.sh` is the old command-line installer and is kept only as a reference: the assistant
(`assistant/internal/deploy`) is its Go port, and line numbers in comments point back at it. It also
tries to install the retired upload-server (`upload-server-go/` was not migrated here), so it can no
longer be run directly.

Build output lands in `dist/` (not checked in) and is picked up by the assistant when it bundles:
`cd assistant && make bundle`. The librime source tree in `third_party/` (about 430 MB) is also local-only.

Not migrated (still in the rmkit repo): Android dual-boot (`android/`), the old desktop assistant
(`desktop/`, replaced by `assistant/`), the old backend `upload-server-go/` (replaced by `space-server`),
`legacy/`, firmware QML exports in `qml-dump/`, and the raw IME dictionary corpus
`ime-go/tools/build_dict/cpd.txt` (43 MB — the built dictionary already lives in `ime-go/pinyin/dict/`).

Third-party code and licenses: see [NOTICE.md](NOTICE.md) and `third-party-licenses/`.
