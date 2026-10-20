# Space — the rmkit-cn launcher

[中文](docs-space-README.md) · English

Space is your digital home on the reMarkable: one home screen (time, weather, today's plan, what is in
progress), a set of apps, and an app store. It replaces the old "Advanced" panel as the single entry
point for everything in rmkit-cn.

The design goal, in one line: **a small, stable shell; apps that are independent; install and uninstall
without rebooting.**

```
Sidebar → "Space" ──▶ Shell Space.qml ──▶ Home / Apps / Discover / Mine
                             │
                             ├── GET /space/apps ──▶ upload-server internal/space (registry)
                             │                        ├── /home/root/rmkit-cn/space/apps/<id>/           built-in apps (installer-managed)
                             │                        └── /home/root/.local/share/rmkit-cn/space/apps/<id>/  user apps (portable install)
                             │
                             └── tap an app ──▶ Qt.createComponent(file://…/main.qml) ──▶ app root Item (property var space)
                                                   └── declared a service ──▶ POST /space/apps/<id>/service/start ──▶ app's own background process
```

## Layers and boundaries

| Layer | Location | Responsibility | What it does not do |
|---|---|---|---|
| Injector | `intercept/qml-inject/qml_inject_impl.cpp` | Puts an entry in the sidebar; if `space/.primary` exists, loads the shell, otherwise loads the old panel | Does not know about any app |
| Shell | `space/shell/Space.qml` | Home screen / tabs, app creation and teardown, the API object given to apps | Contains no business logic |
| Kit | `space/kit/` | Tiles, buttons, radios, list rows, clock, line icons | Holds no state |
| Backend | `upload-server-go/internal/space/` | Scans manifests, portable install / uninstall, hosts app background processes, proxies the store index | Does not know about any app |
| App | `space/apps/<id>/` (built-in) or user directory | A directory: manifest + QML + icon + optional background | Does not touch the shell's internal ids |

Between the shell and an app there are only two wires: the registry JSON (backend → shell) and the
`space` API object (shell → app). Between an app and its own background process the app talks directly
over `space.serviceUrl` — the upload-server is not involved past starting and stopping it.

## App package

```
<id>/
  manifest.json     manifest (required)
  main.qml          UI entry (entry)
  icon.svg          icon
  widget.qml        home-screen widget (optional)
  bin/<service>     bundled background (optional, executable bit set automatically on unzip)
  assets/…          anything
```

`manifest.json` fields (`upload-server-go/internal/space/manifest.go` is the only source of truth):

```json
{
  "id": "music",                 // lowercase letters/digits/-/_, 1–32 chars, also the directory name
  "name": "音乐", "name_en": "Music", "version": "1.0.0",
  "description": "one-line description",
  "icon": "icon.svg",            // relative path / absolute path / qrc: or file: URL
  "entry": "main.qml",           // UI entry; at least one of entry or launch required
  "widget": "widget.qml",        // home-screen widget (optional)
  "widget_size": "half",         // half (half-width card) / hero (full-width hero card at the top, e.g. weather)
  "category": "tool",            // system / settings / reader / tool / game / other
  "order": 10,                   // sort order within category
  "arch": ["aarch64"],           // supported arch; empty = all (rm2 is armv7)
  "min_shell": 1,                // required shell contract version
  "service": {                   // bundled background (optional)
    "exec": "bin/music-server", "args": [], "port": 9100, "health": "/health",
    "keepalive": true,           // keeps running after the UI closes (background playback)
    "autostart": false           // started by upload-server at boot
  },
  "launch": {                    // external-program app (no QML UI, tapping the icon launches it)
    "type": "post",              // post: POST to upload-server; appload: xovi appload singleton
    "path": "/apps/android/launch", "id": "external::koreader",
    "confirm": "Will reboot into Android, continue?"   // non-empty prompts first
  }
}
```

The background process receives these environment variables: `SPACE_APP_ID`, `SPACE_APP_DIR`,
`SPACE_DATA_DIR`, `SPACE_PORT`, `SPACE_BASE_URL`. stdout and stderr are written to
`SPACE_DATA_DIR/service.log`. The whole process group is taken down together — do not fork out of it.

## App UI contract (shell version 1)

The root element is an `Item` that declares `property var space`, which the shell injects at creation
time; `anchors.fill: parent` fills the content area.

```qml
import QtQuick
import "file:///home/root/rmkit-cn/space/kit" as Kit   // shared components (optional)

Item {
    id: root
    property var space
    anchors.fill: parent
    Component.onCompleted: space.get("/bt/status", function(st, r) { … })
}
```

The `space` object:

| Member | Meaning |
|---|---|
| `baseUrl` | upload-server address `http://127.0.0.1:8080` |
| `serviceUrl` | address of the app's own background (only set if the manifest declared a port) |
| `appId` `appDir` `dataDir` `kitDir` | directories and identifiers |
| `unit` `fontScale` `largeScreen` `screenWidth` `screenHeight` | size baseline (see below) |
| `title` | changing it changes the shell's big title |
| `chrome` | set to false and the shell hides the nav bar and title; the app draws its own full-screen UI (like the music player page) |
| `onBack` | assign a function; return true if the app has consumed the back key |
| `exit()` `closeSpace()` `toast(msg)` `openApp(id)` | exit / close the launcher / show a toast / jump to another app |
| `get/post(path, cb)` `svcGet/svcPost(path, cb)` `request(method, url, body, cb)` | HTTP helpers, `cb(status, json)` |
| `localNow()` | current time in the device's local timezone (the system clock is UTC, do not display `new Date()` directly) |
| `dataGet(id, key, cb)` `dataPut(id, key, obj, cb)` | app data persistence (`dataDir/<key>.json`, ≤1 MB JSON); pure-QML apps can also store config and cache |

Widgets (`widget.qml`): root Item + `property var space` + `property var app` (this app's registry entry
including `serviceUrl`, `iconUrl`, `dataDir`; `space.serviceUrl` points to the app currently open, so
widgets must not use it). The shell places the widget in a fixed-height card; tapping it opens the app
via `space.openApp(app.id)`.

### Do not hardcode sizes

Two devices (Paper Pro 1620×2160 @229ppi, Paper Pro Move 954×1696 @264ppi) have similar DPI but nearly 2×
difference in width, and the orientation can rotate too. The shell's approach, which apps should copy:

- `unit = min(width, height) / 954`: Move portrait = 1, Paper Pro ≈ 1.7. Multiply margins, card heights,
  and spacing by it.
- `fontScale = 1 + (unit − 1) × 0.35`: scale font sizes gently (Paper Pro 24 → 30 px).
- Column count comes from content width: `floor(contentWidth / (min tile width × fontScale))` — landscape
  gains columns automatically.

## Localisation

The UI language follows the reMarkable's system setting. Apps do not decide this themselves and do not
store a preference of their own.

The shell locks in a language in this order; the result goes into `space.lang` (`zh-CN` / `en`):

1. `languageSettings.languageCode` — xochitl's live value, i.e. what the user picked in system settings
2. `lang` returned by `/space/apps` — fallback when the shell cannot read the value above; the backend
   infers it from `xochitl.conf` `Language` → `Keyboard` → environment variables
3. `en`

Normalisation: `zh_CN` / `zh-Hans` / `zh` all count as `zh-CN`; Traditional Chinese is currently served
the Simplified dictionary (closer than falling back to English).

### How apps use it

Add an `i18n/` directory to the package, one JSON per language; keys are flat:

```
app/
  manifest.json
  main.qml
  i18n/
    en.json       required — missing keys fall back to this
    zh-CN.json
```

```json
{ "add_task": "添加任务", "done": "完成", "empty_hint": "还没有任务" }
```

In QML:

```qml
Text { text: space.tr("empty_hint") }
Button { text: space.tr("add_task") }
```

**Inside a widget use `space.trApp(app.id, "key")`, not `space.tr`.** Widgets and apps share the same
`space` object, and `space.tr` looks up "the currently open app" — the home screen usually has nothing
open, so it would find an empty dictionary (leaking the key through) or the dictionary of the previously
opened app.

```qml
Text { text: space.trApp(app.id, "now_playing") }
```

When `n` equals 1 it looks for `<key>_one` first — handy for English singular/plural
(`"n_albums": "{n} albums"`, `"n_albums_one": "1 album"`); not needed in Chinese.

If a key is not found it falls back to `en.json`, then to the key itself — **it never shows blank**, so
the worst you ever see is an English key, which makes a missing translation obvious at a glance.

Dictionaries are loaded **synchronously** by the shell (the shell's own during property init, apps' before
`createComponent`), so the first frame has the right text and apps do not need to wait for `space.lang`
to settle. They are a few KB of local `file://` JSON — a few milliseconds.

### Do not use `qsTr`

The injected QML cannot find Qt's translation table (verified empirically); `qsTr("添加")` returns the
Chinese string as-is. Always go through `space.tr()`.

### Why strings are not baked into the binary

Empirically, `qt_add_qml_module`'s output `.so` files are fully readable as QML source including
comments — baking strings in does not protect source code; it only turns "add a language" into "rebuild
for two architectures". So strings live in external JSON: translators do not touch code and adding a
language needs no compilation.

Logic that truly needs protection belongs in the Go backend (`service.exec`), where the compiled source
really is unreadable.

## Backend endpoints

| Method | Path | Meaning |
|---|---|---|
| GET | `/space/apps` | registry: `{shell, arch, userDir, apps:[…]}`, each entry has resolved `entryUrl`, `iconUrl`, `widgetUrl`, `dataDir`, `serviceUrl`, `builtin`, `error` |
| POST | `/space/apps` | upload-install a zip (multipart field `file`, or body is the zip directly) |
| POST | `/space/apps/install-url` | `{"url", "sha256"}` install from URL |
| DELETE | `/space/apps/{id}` | uninstall (user directory only; data directory kept) |
| GET/POST | `/space/apps/{id}/service`, `…/service/start`, `…/service/stop` | app background status / start (returns once ready) / stop |
| GET/PUT | `/space/apps/{id}/data/{key}` | app data (JSON file at `dataDir/<key>.json`) |
| GET | `/space/store` | store index (fetched on-device and cached 10 minutes; `?refresh=1` forces a refetch) |

Inside the zip, `manifest.json` may live at the root or inside a single top-level directory; path
traversal and symlinks are rejected; the zip is extracted to a temp directory, verified, then atomically
swapped in — failure does not affect the installed version; a running background with the same name is
stopped first.

## App store

The index is a static JSON (by default `-space-store` points at
`https://boangs.com/rmkit-space/index.json`, generated and uploaded by each app project's `build.sh`):

```json
{"apps": [{"id": "music", "name": "音乐", "version": "1.0.0", "description": "…",
           "category": "tool", "arch": ["aarch64"],
           "zip": "https://…/music-1.0.0.zip", "sha256": "…"}]}
```

The Discover page compares by id to the local versions: not installed shows "Get", a different version
shows "Update", the same version shows "Installed".

## Migration path

1. **Done**: shell + backend + kit; every page from the old panel has been migrated into a built-in
   app — settings-type pages (QR upload, personalise, AI settings, IME, Bluetooth, Android) are listed
   row-by-row under the "Settings" tab, games/tools (Gomoku, chess, 15-puzzle, Yacht dice, function
   plotter) and KOReader / WeChat Reader are under "Apps". The old "Advanced" panel home screen keeps a
   single "Space" tile as a transitional entry.
2. Drop `/home/root/rmkit-cn/space/.primary` on the device (the rebuilt injector reads it to switch the
   sidebar entry to "Space"), then delete `adv_panel.qml` and the qmd version (the qmd/qmldiff path no
   longer carries new features).
3. Music was the first third-party app (source outside this repo), verifying the whole
   service/keepalive/widget pipeline. Done. Weather was the first built-in app with a hero widget
   (Open-Meteo data source, multi-city, lifestyle index). Done.
4. Dev mode: `touch ~/.local/share/rmkit-cn/space/.dev` and the shell will bypass the QML component
   cache when opening apps — change a QML file and tapping back in picks it up.

## Local development

- In dev mode (`touch ~/.local/share/rmkit-cn/space/.dev`), `scp` a changed **QML file** for the shell or
  an app and reopen Space — the change takes effect without restarting xochitl, because the shell appends
  a timestamp to each QML URL to work around the engine cache.
- **But `.js` and image resources do not get this treatment.** `import "x.js"` has a static URL, and
  SVG/PNG go into `QQuickPixmapCache` by URL, so changes require a one-time xochitl restart to pick up.
  Changing QML does not; changing JS or icons/illustrations does.
- The `dev` flag in the registry must be set before `apps` is assigned (see the order in the shell's
  `reload()`), otherwise the first widget mount happens before cache-busting is on, the old version gets
  cached by the engine, and later QML changes have no effect.
- When an app fails to load, the shell shows `Component.errorString()` directly in the content area.
- `qmllint space/shell/Space.qml` will complain about missing `device.ui.controls` and absolute-path
  imports on Mac — only look at the `Error` lines.
- Backend: `cd upload-server-go && go test ./internal/space/`.
