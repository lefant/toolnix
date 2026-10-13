#!/usr/bin/env bash
# Exercise agent-browser 0.38.1 against a loopback fixture, never a personal profile.
# Usage: bash scripts/check-agent-browser-sessions.sh /absolute/wrapped/agent-browser [screenshot.png]
set -euo pipefail
browser=${1:?Pass the absolute Toolnix agent-browser executable}
[[ "$browser" = /* && -x "$browser" ]] || exit 2
screenshot=${2:-}
# Darwin's per-user TMPDIR can exceed the Unix socket path limit.
root=$(mktemp -d /tmp/ab-proof.XXXXXX)
namespace="proof-$$"
mkdir -p "$root/home" "$root/site" "$root/tmp"
printf '{}\n' > "$root/config.json"
ab() {
  local session=$1
  shift
  env -i PATH="$PATH" HOME="$root/home" TMPDIR="$root/tmp" \
    XDG_CONFIG_HOME="$root/home/.config" XDG_CACHE_HOME="$root/home/.cache" \
    XDG_STATE_HOME="$root/home/.local/state" \
    "$browser" --config "$root/config.json" --namespace "$namespace" --session "$session" "$@"
}
cleanup() {
  for session in everyday fresh writer reader parallel-a parallel-b; do
    ab "$session" close >/dev/null 2>&1 || true
  done
  if [[ -n "${server:-}" ]]; then kill "$server" 2>/dev/null || true; wait "$server" 2>/dev/null || true; fi
  rm -rf "$root"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$root/site/index.html" <<'HTML'
<!doctype html><meta charset="utf-8"><title>Disposable browser proof</title>
<h1>Disposable browser session proof</h1>
<p>Loopback fixture. No personal browser or credentials.</p>
<p id="result">Session state is tested through cookies and localStorage.</p>
HTML
python3 - "$root/site" "$root/port" <<'PY' &
import functools, http.server, pathlib, sys
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=sys.argv[1])
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
pathlib.Path(sys.argv[2]).write_text(str(server.server_port))
server.serve_forever()
PY
server=$!
for ((i=0; i<100; i++)); do
  [[ -s "$root/port" ]] && break
  kill -0 "$server"
  sleep 0.1
done
url="http://127.0.0.1:$(cat "$root/port")/"
set_state() {
  local session=$1 value=$2
  shift 2
  ab "$session" "$@" eval "localStorage.setItem('proof', '$value'); document.cookie='proof=$value; path=/; max-age=3600'; true"
}
expect() {
  local session=$1 value=$2 result
  shift 2
  result=$(ab "$session" "$@" eval "localStorage.getItem('proof') === '$value' && document.cookie === 'proof=$value'")
  [[ "$result" = true ]] || { printf 'FAIL %s expected %s: %s\n' "$session" "$value" "$result" >&2; exit 1; }
}
empty() {
  local result
  result=$(ab "$1" eval "localStorage.getItem('proof') === null && document.cookie === ''")
  [[ "$result" = true ]] || { printf 'FAIL expected fresh state: %s\n' "$result" >&2; exit 1; }
}
ab fresh --version
# "Everyday" is a disposable stand-in, not the user's actual browser.
ab everyday open "$url"
set_state everyday untouched
ab fresh open "$url"
empty fresh
set_state fresh temporary
ab fresh reload
expect fresh temporary
echo 'PASS same-run cookie/localStorage retention'
ab fresh close
ab fresh open "$url"
empty fresh
echo 'PASS close/fresh loses temporary state'
ab writer --restore explicit-proof --restore-save auto open "$url"
set_state writer persistent --restore explicit-proof --restore-save auto
ab writer --restore explicit-proof --restore-save auto close
ab reader --restore explicit-proof --restore-save auto open "$url"
expect reader persistent --restore explicit-proof --restore-save auto
echo 'PASS explicit named restore across distinct sessions'
ab fresh close
ab reader --restore explicit-proof --restore-save auto close
ab parallel-a open "$url" &
pid_a=$!
ab parallel-b open "$url" &
pid_b=$!
wait "$pid_a"
wait "$pid_b"
empty parallel-a
empty parallel-b
set_state parallel-a alpha
set_state parallel-b beta
expect parallel-a alpha
expect parallel-b beta
ab parallel-a close
ab parallel-b close
ab reader --restore explicit-proof --restore-save auto open "$url"
expect reader persistent --restore explicit-proof --restore-save auto
ab reader --restore explicit-proof --restore-save auto close
ab fresh open "$url"
empty fresh
echo 'PASS concurrent session isolation'
expect everyday untouched
echo 'PASS disposable everyday sentinel untouched'
if [[ -n "$screenshot" ]]; then
  ab fresh close
  ab reader --restore explicit-proof open "$url"
  ab reader --restore explicit-proof set viewport 1280 720 2
  ab reader --restore explicit-proof eval "document.getElementById('result').textContent = 'PASS: same-run retention, fresh loss, named restore, parallel isolation, untouched sentinel.'"
  ab reader --restore explicit-proof screenshot "$screenshot"
fi
echo 'PASS all browser session checks'
