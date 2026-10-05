#!/bin/bash
# Builds EVIDENCE.md from the real command output saved in evidence/*.txt
DIR="$(cd "$(dirname "$0")" && pwd)"
EV="$DIR/evidence"
OUT="$DIR/EVIDENCE.md"
block() {  # title, command shown, file, what it proves
  echo "## $1"; echo; echo "Proves: $4"; echo; echo '```'; echo "\$ $2"
  if [ -s "$3" ]; then tr -d '\r' < "$3"; else echo "(no output captured yet)"; fi
  echo '```'; echo
}
{
  echo "# Backend A - Evidence (Mac 3, 10.7.2.229:3001)"
  echo
  echo "Owner: Kanishk. Every block below is real terminal output captured on Mac 3 with tee."
  echo "Matching screenshots, where taken, are in the evidence/ folder."
  echo
  block "1. Backend A running and LAN-bound" "lsof -nP -iTCP:3001 -sTCP:LISTEN" "$EV/04-listen.txt" \
    "the server listens on *:3001 (all interfaces), not only 127.0.0.1."
  block "2. The / endpoint" "curl -si http://10.7.2.229:3001/" "$EV/05-root.txt" \
    "/ answers 200, identifies Backend A in the body, and carries X-Backend: A."
  block "3. The /api/status endpoint" "curl -si http://10.7.2.229:3001/api/status" "$EV/06-status.txt" \
    "/api/status answers 200 with JSON naming backend A, and carries X-Backend: A."
  block "4. Cache headers" "curl -sI http://10.7.2.229:3001/" "$EV/07-cache-headers.txt" \
    "/ is cacheable: Cache-Control: public, max-age=60 plus an ETag validator."
  block "5. Conditional request" "curl -si -H 'If-None-Match: <ETag from step 4>' http://10.7.2.229:3001/" "$EV/08-304.txt" \
    "a client holding the current ETag gets 304 Not Modified with no body."
  block "6. Non-cacheable endpoint" "curl -sI http://10.7.2.229:3001/api/status" "$EV/09-no-store.txt" \
    "live data is marked Cache-Control: no-store, in contrast to /."
  echo "## 7. Server log"; echo
  echo "Proves: which machines made requests. Format: time, client IP, method, path, status."; echo
  echo '```'; echo "\$ cat server.log"; cat "$DIR/server.log" 2>/dev/null; echo '```'; echo
  REMOTE="$(awk '{print $2}' "$DIR/server.log" 2>/dev/null | grep -E '^[0-9]+\.' | grep -v '^10\.7\.2\.229$' | grep -v '^127\.' | sort -u | tr '\n' ' ')"
  echo "## 8. LAN accessibility from another Mac"; echo
  if [ -n "$REMOTE" ]; then
    echo "PROVEN: the log above contains requests from other machine(s): $REMOTE"
  else
    echo "NOT YET PROVEN: every request in the log came from Mac 3 itself (10.7.2.229)."
    echo "A teammate must run the three commands in HANDOFF.md on their own Mac."
  fi
} > "$OUT"
echo "Wrote $OUT"
