#!/usr/bin/env bash
# opendesign-mcp.sh — relocatable stdio launcher for the Open Design MCP
# daemon — **WINDOWS ONLY** (auto-discovery uses the Windows registry and
# Windows named pipes). On macOS/Linux, configure the MCP server manually
# following the app's own agent-integration instructions — see
# https://open-design.ai (the app can generate its MCP registration for you).
#
# Why this exists: the Open Design desktop app ships an MCP daemon, but its
# stock MCP registration hardcodes machine-specific paths AND a named pipe
# whose id is generated at app startup — a static config can never be shipped
# in a portable plugin. This wrapper resolves everything at launch time:
#
#   1. install dir  — registry InstallLocation, then %LOCALAPPDATA%\Programs
#   2. daemon-cli   — <install>/resources/app/prebundled/daemon/daemon-cli.mjs
#   3. pipe         — $OD_SIDECAR_CLIENT_ENDPOINT if set, otherwise the live
#                     \\.\pipe\open-design-sidecar-* endpoints are enumerated
#                     and handshake-probed (initialize round-trip)
#
# The Open Design DESKTOP APP MUST BE RUNNING — the daemon bridges to it over
# the sidecar pipe; without the app there is nothing to connect to.
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

# ── 2. resolve the sidecar pipe ────────────────────────────────────────────
PIPE="${OD_SIDECAR_CLIENT_ENDPOINT:-}"
if [ -z "$PIPE" ]; then
  # enumerate live pipes; MSYS cannot list \\.\pipe\ — use the Electron binary
  # itself as node (ELECTRON_RUN_AS_NODE) to readdir the pipe filesystem
  pipes="$(ELECTRON_RUN_AS_NODE=1 "$OD_EXE" -e "console.log(require('fs').readdirSync('\\\\\\\\.\\\\pipe\\\\').filter(function(f){return f.indexOf('open-design-sidecar')===0}).join('\n'))" 2>/dev/null || true)"
  [ -n "$pipes" ] || die "no live Open Design sidecar pipe — start the Open Design desktop app first, then retry"  # handshake-probe each candidate (initialize round-trip); first responder wins
  probe_req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"opendesign-mcp-probe","version":"0"}}}'
  for cand in $pipes; do
    if printf '%s\n' "$probe_req" | timeout 15 env ELECTRON_RUN_AS_NODE=1 "$OD_EXE" "$OD_CLI" mcp --daemon-url "$cand" >/dev/null 2>&1; then
      PIPE="$cand"
      break
    fi
  done
  [ -n "$PIPE" ] || die "Open Design sidecar pipes exist but none answered the MCP handshake — restart the Open Design desktop app and retry"
fi

# ── 3. hand the transport to the client ────────────────────────────────────
exec env ELECTRON_RUN_AS_NODE=1 "$OD_EXE" "$OD_CLI" mcp --daemon-url "$PIPE"
