#!/usr/bin/env bash
# Runs the price pattern from flag-solicitation.yml over a table of inputs, with the
# same grep -qiE the workflow uses. Set PATTERN to try a different pattern.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
if [ -z "${PATTERN:-}" ]; then
  PATTERN="$(sed -n "s/.*grep -qiE '\(.*\)'; then\$/\1/p" "$here/../.github/workflows/flag-solicitation.yml")"
fi
[ -n "$PATTERN" ] || { echo "could not read the pattern"; exit 2; }
echo "pattern: $PATTERN"

fail=0
check() { # expected input
  if printf '%s' "$2" | grep -qiE "$PATTERN"; then got=hit; else got=miss; fi
  if [ "$got" = "$1" ]; then r=ok; else r=WRONG; fail=1; fi
  printf '%-6s expect %-5s got %-5s %s\n' "$r" "$1" "$got" "$2"
}

for t in "errors 2" "hours 5" "users 3" "parsers 2" "Others 4" "winr 3"; do check miss "$t"; done
for t in '$50' "USD 100" "Rs. 500" "rs 200" "₱1000" "£20" "eur 30" "INR 40" "I can do it, usd50" "rs.500" "my rate is fine"; do check hit "$t"; done
exit $fail
