#!/usr/bin/env bash
# build_agents.sh — regenerate codex/agents/*.toml from ../agents/*.md
#
# Why: Codex plugins can bundle skills, hooks, and MCP servers, but NOT
# subagents (the official Claude-plugin submission guide says agents must be
# converted). Codex's native subagent format is one TOML file per agent with
# the agent's system prompt in `developer_instructions`. The generated files
# are seeded into a workspace's .codex/agents/ by game-studios-init.
#
# Run this after adding or editing agents/*.md, then commit the output:
#   bash codex/build_agents.sh
set -eu
cd "$(dirname "$0")"
mkdir -p agents
count=0
for f in ../agents/*.md; do
  base="$(basename "$f" .md)"
  awk '
    FNR == 1 { infm = 0; donefm = 0; name = ""; desc = ""; body = "" }
    !donefm && $0 == "---" { if (infm) donefm = 1; else infm = 1; next }
    infm && !donefm {
      if ($0 ~ /^name:/) {
        name = substr($0, 6); gsub(/^[ \t]+|[ \t]+$/, "", name)
        sub(/^"/, "", name); sub(/"$/, "", name)
      } else if ($0 ~ /^description:/) {
        d = substr($0, 13)
        sub(/^[ \t]+/, "", d)
        sub(/^"/, "", d); sub(/"[ \t\r]*$/, "", d)
        gsub(/\\"/, "\"", d); gsub(/\\\\/, "\\", d)
        desc = d
      }
      next
    }
    donefm { gsub(/\r$/, ""); body = body $0 "\n" }
    END {
      if (name == "" || desc == "" || body == "") {
        printf "build_agents: %s: missing name/description/body\n", FILENAME > "/dev/stderr"
        exit 1
      }
      # TOML literal strings (no escape processing); bodies never contain """
      # (\047 = single quote — octal, unlike \x27, is POSIX awk)
      q = "\047\047\047"
      printf "name = \"%s\"\n", name
      printf "description = %s%s%s\n", q, desc, q
      printf "developer_instructions = %s\n%s%s\n", q, body, q
    }
  ' "$f" > "agents/$base.toml"
  count=$((count + 1))
done
echo "generated $count Codex agent definitions in codex/agents/"
