# Panxito apps for remarkable-space

Five Space apps that pull from the Panxito home-infra stack on the Tailnet. All HTTP GET only, 6–15 s timeout, 2–15 min auto-refresh.

| App | Widget | Backend endpoint | Payload shape (minimal) |
|---|---|---|---|
| `panxito-today` | hero | `http://panxito-today.l4local.net/api/today` | `{weather:{summary,temp_f}, agenda:[{time,title,location?}], overdue:[{title,due?}]}` |
| `apple-health` | half | `http://health.l4local.net/api/today` + `/api/summary` | `{steps,resting_hr,last_workout:{kind,duration_min}}` and `{today:…, recent_workouts:[{date,kind,duration_min}]}` |
| `money` | half | `http://simplefin.l4local.net/api/summary` + `/api/accounts` | `{total,last_refresh}` and `{accounts:[{name,balance}], total}` |
| `flap` | half | `http://flap.l4local.net/api/current` + `/api/history?limit=20` | `{text,sender}` and `{current:{text,sender}, history:[{at,text,sender}]}` |
| `l4local` | half | `http://tools.l4local.net/api/status` | `{services:[{name,status}]}` with `status` ∈ `ok`/`broken`/`unknown` |

## Requirements

- reMarkable on the Tailnet (Tailscale installed on-device). All `.l4local.net` hostnames resolve only inside the tailnet.
- The listed `/api/*` endpoints don't exist yet on the Panxito side — these apps are the *consumer* shape; the backends need thin JSON wrappers that match the schemas above. Easiest path: add a shim handler to each existing service in `~/vps/`.
- Chinese + English via `i18n/`. `name_en` in each manifest.

## Install path

Once the backend shims exist and the app zips are built:

```sh
# Build a zip per app:
cd apps/panxito-today && zip -r ../../dist/panxito-today-0.1.0.zip .
# Then upload via the Space Assistant → scan QR, or:
curl -F file=@panxito-today-0.1.0.zip http://<device>:8080/space/apps
```

Or drop them into the "built-in" set by committing them under `apps/` and running the installer, which is what this directory already does.

## Not implemented

- No service background (no `service` block in manifests) — pure QML + XHR.
- No write actions (read-only widgets, matching how you'd use the tablet).
- No auth headers. All backends are tailnet-gated at nginx/Caddy already.
