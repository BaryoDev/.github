#!/usr/bin/env bash
# Checks for .github/workflows/announce.yml: job permissions, and the idempotency lookup run
# against a fake gh. Needs python3 with PyYAML.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WF="$ROOT/.github/workflows/announce.yml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (want $2, got $3)"; fail=1; fi; }

python3 - "$WF" "$TMP" <<'PY'
import sys, yaml
class L(yaml.SafeLoader): pass
def mp(loader, node, deep=False):
    seen = set()
    for k, _ in node.value:
        key = loader.construct_object(k, deep=True)
        if key in seen: raise SystemExit("duplicate key: %s" % key)
        seen.add(key)
    return yaml.SafeLoader.construct_mapping(loader, node, deep)
L.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mp)
d = yaml.load(open(sys.argv[1]), Loader=L)
job = d["jobs"]["announce"]
open(sys.argv[2] + "/perms", "w").write(repr(job.get("permissions")))
open(sys.argv[2] + "/post.sh", "w").write(job["steps"][0]["run"])
open(sys.argv[2] + "/discord.sh", "w").write(job["steps"][1]["run"])
PY
check "job sets permissions: {}" "{}" "$(cat "$TMP/perms")"
check "discord curl has --max-time" 1 "$(grep -c -- '--max-time' "$TMP/discord.sh")"

mkdir "$TMP/bin"
run() { # $1 = fake gh body
  printf '#!/usr/bin/env bash\n%s\n' "$1" > "$TMP/bin/gh"; chmod +x "$TMP/bin/gh"
  : > "$TMP/calls"
  PATH="$TMP/bin:$PATH" PACKAGE=pkg VERSION=v1.0.0 NOTES= INSTALL= CALLS="$TMP/calls" \
    bash "$TMP/post.sh" >/dev/null 2>&1
  echo $?
}
LIST='case "$*" in *createDiscussion*) echo create >> "$CALLS"; echo http://x;; *) '
check "failed list read fails the step" 1 "$(run "${LIST}exit 1;; esac")"
check "failed list read posts nothing" 0 "$(grep -c create "$TMP/calls")"
check "empty list still posts" 0 "$(run "${LIST}:;; esac")"
check "empty list creates one" 1 "$(grep -c create "$TMP/calls")"
check "existing title skips" 0 "$(run "${LIST}echo 'pkg v1.0.0';; esac")"
check "existing title posts nothing" 0 "$(grep -c create "$TMP/calls")"
exit $fail
