#!/usr/bin/env bash
# opendesign-mcp.sh — relocatable stdio launcher for the Open Design MCP
# daemon — **WINDOWS ONLY** (auto-discovery uses the Windows registry and
# Windows named pipes). On macOS/Linux, configure the MCP server manually
# following the app's own agent-integration instructions — see
# https://open-design.ai (the app can generate its MCP registration for you).
#
# Why this exists: the Open Design desktop app ships an MCP daemon
# (prebundled/daemon/daemon-cli.mjs), but reaching it requires two
# machine-specific facts a static config can never carry:
#
#   1. the install dir          — resolved via registry InstallLocation,
#                                 then %LOCALAPPDATA%\Programs
#   2. the daemon's HTTP port   — allocated at runtime (NOT the default
#                                 http://127.0.0.1:7456), discoverable only
#                                 through the app's sidecar named pipe, whose
#                                 id is regenerated every app session.
#
# The transport contract (reverse-engineered from @open-design/sidecar):
#   OD_SIDECAR_CLIENT_ENDPOINT=<\\.\pipe\open-design-sidecar-<id>>  →
#   daemon-cli asks that pipe {"type":"sidecar:status"} and gets the live
#   http:// URL of the daemon. This wrapper finds such a pipe via
#   opendesign-discover.js (executed by the app's own Electron binary in node
#   mode) and hands it to daemon-cli through the environment.
#
# The Open Design DESKTOP APP MUST BE RUNNING — without it there is no
# sidecar pipe and no daemon.
#
# Referenced from the plugin's .mcp.json / mcp.json as:
#   { "command": "bash", "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/opendesign-mcp.sh"] }

set -u

die() { echo "opendesign-mcp: $*" >&2; exit 1; }

case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) die "auto-discovery is Windows-only (registry + named pipes). On macOS/Linux, configure the open-design MCP server manually — the app can generate its registration for you; see https://open-design.ai" ;;
esac

p() { # Windows path -> POSIX path (Git Bash)
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1" 2>/dev/null || printf '%s' "$1"; else printf '%s' "$1"; fi
}

# ── 1. locate the install ──────────────────────────────────────────────────
OD_INSTALL=""
if command -v reg >/dev/null 2>&1; then
  for hive in 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Open Design-release-stable-win' \
              'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Open Design-release-stable-win'; do
    loc="$(MSYS_NO_PATHCONV=1 reg query "$hive" /v InstallLocation 2>/dev/null | grep REG_SZ | sed 's/.*REG_SZ *//' | tr -d '\r')"
    if [ -n "$loc" ] && [ -f "$(p "$loc")/Open Design.exe" ]; then OD_INSTALL="$(p "$loc")"; break; fi
  done
fi
if [ -z "$OD_INSTALL" ] && [ -n "${LOCALAPPDATA:-}" ]; then
  cand="$(p "$LOCALAPPDATA")/Programs/Open Design"
  [ -f "$cand/Open Design.exe" ] && OD_INSTALL="$cand"
fi
[ -n "$OD_INSTALL" ] || die "Open Design is not installed; get the desktop app from https://open-design.ai/download (Windows auto-discovery only — other hosts: configure the MCP manually per https://open-design.ai)"

OD_EXE="$OD_INSTALL/Open Design.exe"
OD_CLI="$OD_INSTALL/resources/app/prebundled/daemon/daemon-cli.mjs"
[ -f "$OD_EXE" ] || die "Open Design.exe not found at $OD_EXE"
[ -f "$OD_CLI" ] || die "daemon-cli.mjs not found at $OD_CLI (unexpected app layout)"

# ── 2. resolve the sidecar pipe (daemon front) ─────────────────────────────
if [ -z "${OD_SIDECAR_CLIENT_ENDPOINT:-}" ]; then
  HERE="$(cd "$(dirname "$0")" && pwd)"
  PIPE="$(ELECTRON_RUN_AS_NODE=1 "$OD_EXE" "$HERE/opendesign-discover.js" 2>/dev/null | head -1 | tr -d '\r')"
  [ -n "$PIPE" ] || die "no live Open Design sidecar pipe — start the Open Design desktop app first, then retry"
  export OD_SIDECAR_CLIENT_ENDPOINT="$PIPE"
fi

# ── 3. hand the transport to the client ────────────────────────────────────
# daemon-cli resolves the daemon's dynamic http:// URL through the sidecar
# endpoint env on its own; no --daemon-url (which only accepts literal URLs).
exec env ELECTRON_RUN_AS_NODE=1 "$OD_EXE" "$OD_CLI" mcp
