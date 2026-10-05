#!/bin/bash
# Backend A - restart the server, run every test, and collect evidence.
# Run on Mac 3 with:  bash MAC_3/Backend_A/collect-evidence.sh
# Safe to run as many times as you like.

DIR="$(cd "$(dirname "$0")" && pwd)"
IP="${BACKEND_IP:-10.7.2.229}"
PORT=3001
URL="http://$IP:$PORT"
EV="$DIR/../evidence"
mkdir -p "$EV"
cd "$DIR" || exit 1

# Wait for a screenshot, then file the newest Desktop screenshot under the given name.
shot() {
  local name="$1" marker newest="" f ext
  marker="$(mktemp)"
  echo
  echo "------------------------------------------------------------"
  echo " SCREENSHOT NOW:  Cmd+Shift+4, then Space, then click this window"
  echo " Then press Enter here.   (will be saved as evidence/$name.png)"
  echo "------------------------------------------------------------"
  read -r _
  sleep 1
  while IFS= read -r f; do
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
  done < <(find "$HOME/Desktop" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.heic' -o -iname '*.jpg' -o -iname '*.jpeg' \) -newer "$marker" 2>/dev/null)
  rm -f "$marker"
  if [ -n "$newest" ]; then
    ext="$(printf '%s' "${newest##*.}" | tr 'A-Z' 'a-z')"
    if [ "$ext" != "png" ] && command -v sips >/dev/null 2>&1 \
       && sips -s format png "$newest" --out "$EV/$name.png" >/dev/null 2>&1; then
      rm -f "$newest"
      echo "Saved evidence/$name.png (converted from .$ext)"
    else
      mv "$newest" "$EV/$name.$ext" && echo "Saved evidence/$name.$ext"
    fi
  else
    echo "No new screenshot found on the Desktop. If you took one, move it into"
    echo "evidence/ yourself and name it $name.png"
  fi
  sleep 1
}

# ---- Preflight -------------------------------------------------------------
MYIP="$(ipconfig getifaddr en0 2>/dev/null)"
if [ "$MYIP" != "$IP" ]; then
  echo "STOP: this Mac's Wi-Fi IP is '${MYIP:-unknown}', but the project expects $IP."
  echo "Nothing was changed. Tell Deepanshu the new IP, then send this message to Claude."
  exit 1
fi

# ---- Step 1: clean restart --------------------------------------------------
clear
echo "STEP 1  Backend A running and listening on the LAN"
echo
pkill -f "$DIR/server.js" 2>/dev/null
sleep 1
nohup node "$DIR/server.js" >> "$DIR/server.log" 2>&1 &
sleep 2
echo "\$ tail -n 1 server.log"
tail -n 1 "$DIR/server.log"
echo
echo "\$ lsof -nP -iTCP:$PORT -sTCP:LISTEN"
lsof -nP -iTCP:$PORT -sTCP:LISTEN | tee "$EV/04-listen.txt"
if ! curl -s -m 3 -o /dev/null "$URL/api/status"; then
  echo
  echo "STOP: Backend A did not start. Send the text above to Claude."
  exit 1
fi
shot "03-04-running-and-listening"

# ---- Step 2: / ---------------------------------------------------------------
clear
echo "STEP 2  The / endpoint"
echo
echo "\$ curl -si $URL/"
curl -si "$URL/" | tee "$EV/05-root.txt"
shot "05-root"

# ---- Step 3: /api/status -----------------------------------------------------
clear
echo "STEP 3  The /api/status endpoint"
echo
echo "\$ curl -si $URL/api/status"
curl -si "$URL/api/status" | tee "$EV/06-status.txt"
shot "06-status"

# ---- Step 4: cache headers ---------------------------------------------------
clear
echo "STEP 4  Cache headers on /"
echo
echo "\$ curl -sI $URL/"
curl -sI "$URL/" | tee "$EV/07-cache-headers.txt"
shot "07-cache-headers"

# ---- Step 5: conditional request -> 304 --------------------------------------
clear
echo "STEP 5  Conditional request returns 304"
echo
ETAG="$(curl -sI "$URL/" | awk -F': ' 'tolower($1)=="etag"{print $2}' | tr -d '\r')"
echo "ETag is: $ETAG"
echo
echo "\$ curl -si -H 'If-None-Match: $ETAG' $URL/"
curl -si -H "If-None-Match: $ETAG" "$URL/" | tee "$EV/08-304.txt"
shot "08-304"

# ---- Step 6: non-cacheable endpoint ------------------------------------------
clear
echo "STEP 6  /api/status is not cacheable"
echo
echo "\$ curl -sI $URL/api/status"
curl -sI "$URL/api/status" | tee "$EV/09-no-store.txt"
shot "09-no-store"

# ---- Step 7: LAN test from a teammate's Mac ----------------------------------
clear
echo "STEP 7  LAN test - this part happens on a TEAMMATE'S Mac"
echo
echo "Ask Adarsh (Mac 4) or Deepanshu (Mac 2) to run these on THEIR laptop:"
echo
echo "    ipconfig getifaddr en0"
echo "    curl -si $URL/"
echo "    curl -si $URL/api/status"
echo
echo "They screenshot their Terminal and send it to you (10-lan-from-teammate.png)."
echo
echo "Press Enter here AFTER they have run the commands."
echo "(No teammate available right now? Press Enter anyway and redo this step later.)"
read -r _

# ---- Step 8: server log with the remote IP -----------------------------------
clear
echo "STEP 8  Server log"
echo
echo "\$ cat server.log"
cat "$DIR/server.log"
echo
REMOTE="$(awk '{print $2}' "$DIR/server.log" | grep -E '^[0-9]+\.' | grep -v "^$IP\$" | grep -v '^127\.' | sort -u | tr '\n' ' ')"
if [ -n "$REMOTE" ]; then
  echo "LAN PROOF OK: requests received from other machine(s): $REMOTE"
  shot "11-server-log-remote-ip"
else
  echo "NOT YET PROVEN: every request so far came from this Mac ($IP)."
  echo "When a teammate has run the commands, run:  cat $DIR/server.log"
  echo "and screenshot it as 11-server-log-remote-ip.png"
fi

echo
echo "Evidence folder now contains:"
ls -1 "$EV"
echo
echo "Backend A is still running in the background."
