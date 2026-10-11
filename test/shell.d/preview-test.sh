#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
preview_file="$tmp/example.txt"
printf 'hello\n' >"$preview_file"

cat >"$tmp/bin/sushi" <<'SH'
#!/bin/bash
printf 'sushi:%s\n' "$*" >"$OMARCHY_PREVIEW_LOG"
SH
chmod +x "$tmp/bin/sushi"

OMARCHY_PREVIEW_LOG="$tmp/log" PATH="$tmp/bin:/usr/bin:/bin" "$ROOT/bin/omarchy-preview" "$preview_file"
[[ $(<"$tmp/log") == "sushi:$preview_file" ]] ||
  fail "preview uses Sushi when available"
pass "preview uses Sushi when available"

rm -f "$tmp/bin/sushi" "$tmp/log"
cat >"$tmp/bin/gio" <<'SH'
#!/bin/bash
printf 'gio:%s\n' "$*" >"$OMARCHY_PREVIEW_LOG"
SH
chmod +x "$tmp/bin/gio"

OMARCHY_PREVIEW_LOG="$tmp/log" PATH="$tmp/bin:/usr/bin:/bin" "$ROOT/bin/omarchy-preview" "$preview_file"
[[ $(<"$tmp/log") == "gio:open $preview_file" ]] ||
  fail "preview falls back to gio open"
pass "preview falls back to gio open"

if "$ROOT/bin/omarchy-preview" "$tmp/missing" 2>"$tmp/error"; then
  fail "preview rejects missing paths"
fi
grep -q "not found: $tmp/missing" "$tmp/error" ||
  fail "preview reports missing path"
pass "preview rejects missing paths"
