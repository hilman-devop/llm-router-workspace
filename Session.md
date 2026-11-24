# Session: Koneksi Kimi IDE → 9Router

**Tanggal:** 2026-08-03
**Tujuan:** Semua model yang dipilih di Kimi IDE diarahkan ke `bb/blackboxai/moonshotai/kimi-k3` via 9Router lokal.

---

## Arsitektur Final

```
Kimi IDE (daimon, kernel kimi-code in-process)
  └─ HTTPS agent-gw.kimi.com/coding/v1/chat/completions   (HTTP/2 atau HTTP/1.1)
       └─ hosts: agent-gw.kimi.com → 127.0.0.1
            └─ proxy TLS lokal (C:\TheGame\Nyoba\kimi-9router\proxy.js, 127.0.0.1:443)
                 ├─ /chat/completions → model dipaksa bb/blackboxai/moonshotai/kimi-k3
                 │    → http://127.0.0.1:20128/v1 (9Router) → Fireworks → kimi-k3
                 └─ path lain (/models, /search, /fetch, ...) → passthrough ke server Kimi asli
```

**Rantai kepercayaan TLS:** cert `agent-gw.kimi.com` ditandatangani rootCA 9Router (`%APPDATA%\9router\mitm\rootCA.crt`, sudah ada + trusted di Windows store). Agar **node daimon** ikut percaya: `NODE_EXTRA_CA_CERTS` + `KIMI_CAPTURE=1` (lihat "Akar masalah" di bawah).

## Akar Masalah (kenapa sempat "Connection error")

Debug berlapis, tiga temuan:

1. **Chat Kimi memakai HTTP/2.** Proxy awal hanya HTTP/1.1 → koneksi gagal sebelum request (tidak tercatat di log). Fix: `http2.createSecureServer({ allowHTTP1: true })`.
2. **Pseudo-header h2 bocor ke passthrough.** Header `:method`/`:path` ikut diteruskan ke upstream HTTP/1.1 → proxy crash `ERR_INVALID_HTTP_TOKEN` saat `/models` → kernel menganggap provider mati. Fix: buang semua header berawalan `:` di passthrough.
3. **ROOT CAUSE: env daimon adalah allowlist.** Kode desktop app (di `app.asar`, fungsi `buildEnv`) hanya meneruskan `NODE_EXTRA_CA_CERTS`, `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY`, `NODE_USE_ENV_PROXY`, `SSL_CERT_FILE` ke daimon **jika `KIMI_CAPTURE=1`** (mode debug/capture untuk Charles). Tanpa itu, env CA kita sengaja dibuang → TLS ke proxy ditolak → "Connection error" generik (`WORKER_FAILED`) tanpa request pernah sampai ke proxy.

## Kenapa bukan lewat config (jalan buntu yang sudah dicoba)

- Provider bawaan cloud (`daimon-kimi-code`) di-render dari **template di bundle daimon** — edit `config.json` selalu dinormalisasi ulang saat boot.
- Hijack model cloud (`k2d6-agent`) ke provider kustom → `conversations.updateKimiModelList` konflik ("cannot replace existing model ... belongs to provider") → UI memblokir send.
- Provider/model kustom selamat dari reset, tapi dropdown UI hanya menampilkan model dari cloud → tidak bisa dipilih user.

## Komponen

| Komponen | Lokasi / Nilai |
|---|---|
| Proxy TLS (HTTP/2 + HTTP/1.1) | `C:\TheGame\Nyoba\kimi-9router\proxy.js` |
| Runtime proxy (standalone) | `kimi-gw-node.exe` — copy node.exe yang di-rename supaya **tidak ketabrak `taskkill /F /IM node.exe`** dari project lain |
| Watchdog | `run-proxy.vbs` — loop: proxy mati → nyalakan lagi (~2 detik) |
| Cert + key agent-gw | `C:\TheGame\Nyoba\kimi-9router\agent-gw.crt` / `.key` (generator: `make-cert.js`, pakai node-forge dari node_modules 9Router) |
| Autostart | HKCU Run `KimiRouterProxy` → `run-proxy.vbs` |
| hosts | `127.0.0.1 agent-gw.kimi.com` (perlu admin untuk mengubah; ditulis via `add-hosts.ps1` elevated) |
| Env user | `NODE_EXTRA_CA_CERTS` = `%APPDATA%\9router\mitm\rootCA.crt` |
| Env user | `KIMI_CAPTURE` = `1` ← **kunci agar daimon meneruskan env CA** |
| Log proxy | `C:\TheGame\Nyoba\kimi-9router\proxy.log` |
| 9Router combos (tidak dipakai path proxy, tersedia) | `k2d6-agent`, `k3-agent`, `k3-agent-swarm`, `k2p6`, `k2p6-agent` → `bb/blackboxai/moonshotai/kimi-k3` |

## Kredensial

- 9Router: `http://127.0.0.1:20128/v1`, key `sk-API_KEY_DISINI`
- Model target: `bb/blackboxai/moonshotai/kimi-k3`

## Verifikasi (bertahap, semua lulus)

- OpenAI SDK (dari node_modules bundle) → `https://agent-gw.kimi.com/coding/v1/chat/completions`: **200**, stream & non-stream ✅
- HTTP/2 murni + `stream:true`: SSE `reasoning_content` mengalir ✅
- Passthrough `/coding/v1/models` & `/coding/v1/search` sampai ke server Kimi asli (401 tanpa auth / error upstream asli) ✅
- Daimon generasi `KIMI_CAPTURE=1` sukses init `/models` lewat proxy ✅
- **Chat dari UI: CONFIRMED ✅** — `proxy.log` mencatat `CHAT model=k3-agent -> bb/blackboxai/moonshotai/kimi-k3 stream=true` (termasuk call judul percakapan), balasan + thinking tampil normal di UI.

## Revert (kembali normal)

1. Hapus `127.0.0.1 agent-gw.kimi.com` dari hosts (admin):
   `powershell -Command "(Get-Content $env:WINDIR\System32\drivers\etc\hosts) | Where-Object {$_ -notmatch 'agent-gw'} | Set-Content $env:WINDIR\System32\drivers\etc\hosts"`
2. Hapus env:
   ```powershell
   [Environment]::SetEnvironmentVariable('NODE_EXTRA_CA_CERTS',$null,'User')
   [Environment]::SetEnvironmentVariable('KIMI_CAPTURE',$null,'User')
   ```
3. Hapus autostart: `Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name KimiRouterProxy`
4. Kill proxy: cari listener 443 (`Get-NetTCPConnection -LocalPort 443 -State Listen`) → `Stop-Process -Id <pid>`
5. `daimon-share\daimon\config.json` bisa dikembalikan dari `config.json.bak-9router` (opsional; sisa provider `9router` tidak dipakai dan tidak mengganggu).

## Status: DIPENSIUNKAN (2026-08-04)

Kimi Desktop di-uninstall user → seluruh setup proxy di atas sudah **dibongkar bersih**:
- Watchdog + proxy distop, Run key `KimiRouterProxy` dihapus
- hosts `agent-gw.kimi.com` dihapus
- Env `NODE_EXTRA_CA_CERTS` & `KIMI_CAPTURE` dihapus
- `%APPDATA%\kimi-desktop` bersih oleh uninstaller
- Folder ini (proxy.js, cert, vbs) inert — boleh dihapus kapan saja

## Pengganti: Kimi CLI → 9Router

Kimi CLI 1.49.0 diinstall via `uv tool install kimi-cli` (binary: `%USERPROFILE%\.local\bin\kimi.exe`, PATH sudah di-set).

Config `%USERPROFILE%\.kimi\config.toml`:

```toml
default_model = "k3"

[providers.9router]
type = "openai_legacy"        # CLI Python: bukan "openai"; valid: kimi/openai_legacy/openai_responses/anthropic/google_genai/gemini/vertexai
base_url = "http://127.0.0.1:20128/v1"
api_key = "sk-API_KEY_DISINI"

[models.k3]
provider = "9router"
model = "bb/blackboxai/moonshotai/kimi-k3"
max_context_size = 262144
capabilities = ["thinking", "image_in"]
```

Verifikasi: `kimi -p "..." --print` → jawab OK; tercatat di usage 9Router (`blackboxai/moonshotai/kimi-k3`, ok) ✅
Tanpa proxy/hosts/env — CLI ngomong langsung HTTP ke 9Router.

## WebBridge → Kimi CLI

- Daemon: `%USERPROFILE%\.kimi-webbridge\bin\kimi-webbridge.exe` (upgrade v1.11.3 → **v1.11.5**), port 127.0.0.1:10086
- Skill terinstall di `%USERPROFILE%\.kimi\skills\kimi-webbridge\` (juga ke Claude Code, Codex, .kimi-code) via `kimi-webbridge install-skill -y`
- Autostart: HKCU Run `KimiWebBridge` → `%USERPROFILE%\.kimi-webbridge\autostart.vbs` (hidden)
- Browser extension: connected (v1.11.5)
- Verifikasi end-to-end: CLI → 9Router → skill → daemon → extension: `list_tabs` → `{"success":true,"tabs":[]}` ✅
- Tools: navigate, click, fill, snapshot, screenshot, network, save_as_pdf, upload, cdp (browser asli + sesi login user)

## Fitur CLI yang terverifikasi jalan via 9Router

Chat, thinking, tool calling, subagents (`agent`/`coder`/`explore`/`plan` — didemo: subagent explore spawn + 2 generasi via 9Router), background tasks, plan mode, skills, MCP, sessions, image input.
- Web search/fetch resmi: butuh `kimi login` (endpoint Moonshot terpisah, dikonfigurasi otomatis saat login OAuth).
- Swarm: tidak ada di CLI (produk cloud, orkestrasi server-side) — padanannya = subagents lokal.
- Catatan: fitur CLI tidak di-gate nama model (cek `kimi-k2*` hanya kosmetik welcome tip).

## Inventaris file yang dibuat/diubah sesi ini

**Baru:**
- `%USERPROFILE%\.kimi-webbridge\autostart.vbs` — autostart daemon webbridge
- `%USERPROFILE%\.kimi\skills\kimi-webbridge\SKILL.md` + `operations.md` — oleh installer webbridge
**Legacy Kimi Desktop: SUDAH DIHAPUS SEMUA (2026-08-04)** — proxy.js, run-proxy.vbs, kimi-gw-node.exe, make-cert.js, cert agent-gw, skrip hosts, proxy.log, skrip tes temporer, dan combo 9Router (`k2d6-agent`, `k3-agent`, `k3-agent-swarm`, `k2p6`, `k2p6-agent`). Folder ini kini hanya berisi `Session.md`.

**Diubah:**
- `%USERPROFILE%\.kimi\config.toml` — provider `9router` + model `k3` + `default_model = "k3"`
- Registry HKCU Run: `KimiWebBridge` (baru); `KimiRouterProxy` (dihapus)
- hosts: entri `agent-gw.kimi.com` sudah dihapus
- Env user: `NODE_EXTRA_CA_CERTS`, `KIMI_CAPTURE` sudah dihapus

**Terinstall:** `kimi-cli` 1.49.0 via `uv tool` (di `%USERPROFILE%\AppData\Roaming\uv\tools\kimi-cli`), PATH `.local\bin` sudah masuk user PATH.

- Apa pun model yang dipilih di UI (Instant/K3/K3 Swarm/K2.6 Agent), request chat selalu jadi `bb/blackboxai/moonshotai/kimi-k3`.
- **K3 Swarm** digate membership Kimi (Moderato-tier ke atas) — akun Free memang ditolak sisi server, bukan dari setup ini.
- Web search/fetch Kimi tetap lewat server asli (passthrough).
- Update Kimi IDE tidak merusak setup (tidak ada file app yang di-patch). Update 9Router bisa mengubah model id — cek `~/.config/opencode/opencode.json` untuk model terbaru.
- `KIMI_CAPTURE=1` adalah mode debug resmi app; efek samping: daimon meneruskan env proxy (`HTTP(S)_PROXY` bila diset) — saat ini tidak diset, jadi tidak ada efek.
