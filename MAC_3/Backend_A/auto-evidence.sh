#!/bin/bash
# Backend A - one command, no key presses: restart, test, save output, screenshot, report.
# Run on Mac 3 with:  bash MAC_3/Backend_A/auto-evidence.sh     (safe to repeat)
DIR="$(cd "$(dirname "$0")" && pwd)"
IP="${BACKEND_IP:-10.7.2.229}"; PORT=3001; URL="http://$IP:$PORT"; EV="$DIR/../evidence"
mkdir -p "$EV"; cd "$DIR" || exit 1
SHOTS_OK=0; SHOTS_FAIL=0
shot() {  # capture the screen as evidence/<name>.png, without any key press
  sleep 1
  if command -v screencapture >/dev/null 2>&1 && screencapture -x -t png "$EV/$1.png" 2>/dev/null && [ -s "$EV/$1.png" ]; then
    SHOTS_OK=$((SHOTS_OK+1))
  else
    SHOTS_FAIL=$((SHOTS_FAIL+1))
  fi
  sleep 1
}
MYIP="$(ipconfig getifaddr en0 2>/dev/null)"
if [ "$MYIP" != "$IP" ]; then
  echo "STOP: this Mac's Wi-Fi IP is '${MYIP:-unknown}', but the project expects $IP."
  echo "Nothing was changed. Send this text to Claude."
  exit 1
fi

clear; echo "STEP 1  Backend A running and listening on the LAN"; echo
pkill -f "$DIR/server.js" 2>/dev/null; sleep 1
nohup node "$DIR/server.js" >> "$DIR/server.log" 2>&1 &
sleep 2
echo "\$ tail -n 1 server.log"; tail -n 1 "$DIR/server.log"; echo
echo "\$ lsof -nP -iTCP:$PORT -sTCP:LISTEN"
lsof -nP -iTCP:$PORT -sTCP:LISTEN | tee "$EV/04-listen.txt"
if ! curl -s -m 3 -o /dev/null "$URL/api/status"; then
  echo; echo "STOP: Backend A did not start. Send the text above to Claude."; exit 1
fi
shot "03-04-running-and-listening"

clear; echo "STEP 2  The / endpoint"; echo; echo "\$ curl -si $URL/"
curl -si "$URL/" | tee "$EV/05-root.txt"; shot "05-root"

clear; echo "STEP 3  The /api/status endpoint"; echo; echo "\$ curl -si $URL/api/status"
curl -si "$URL/api/status" | tee "$EV/06-status.txt"; echo; shot "06-status"

clear; echo "STEP 4  Cache headers on /"; echo; echo "\$ curl -sI $URL/"
curl -sI "$URL/" | tee "$EV/07-cache-headers.txt"; shot "07-cache-headers"

clear; echo "STEP 5  Conditional request returns 304"; echo
ETAG="$(curl -sI "$URL/" | awk -F': ' 'tolower($1)=="etag"{print $2}' | tr -d '\r')"
echo "ETag is: $ETAG"; echo; echo "\$ curl -si -H 'If-None-Match: $ETAG' $URL/"
curl -si -H "If-None-Match: $ETAG" "$URL/" | tee "$EV/08-304.txt"; shot "08-304"

clear; echo "STEP 6  /api/status is not cacheable"; echo; echo "\$ curl -sI $URL/api/status"
curl -sI "$URL/api/status" | tee "$EV/09-no-store.txt"; shot "09-no-store"

clear; echo "STEP 7  Server log"; echo; echo "\$ cat server.log"; cat "$DIR/server.log"; shot "11-server-log"

bash "$DIR/make-report.sh" >/dev/null
clear
echo "DONE. Backend A is running in the background."
echo
echo "Text evidence + report : $DIR/EVIDENCE.md"
echo "Screenshots saved      : $SHOTS_OK   (failed: $SHOTS_FAIL)"
echo
echo "Evidence folder:"; ls -1 "$EV"
echo
echo "STILL NEEDED - LAN proof. A teammate runs these on THEIR Mac:"
echo "    ipconfig getifaddr en0"
echo "    curl -si $URL/"
echo "    curl -si $URL/api/status"
echo "Afterwards run:  bash $DIR/make-report.sh && cat $DIR/server.log"
