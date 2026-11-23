# pf rollback (Extension C)

All project rules live only in the anchor `com.apple/nova`. Apple's own rules are never touched.

## Before loading (read-only baseline, save the output)
```
sudo pfctl -s info                     # Enabled or Disabled
sudo pfctl -sr                         # must contain: anchor "com.apple/*" all
sudo pfctl -a com.apple -s Anchors -v
sudo pfctl -s References
```

## Enable token (not used on Mac 4)

Mac 4 baseline: pf already **Enabled for 28 days** with no references held. We do **not** run `pfctl -E` / `-X` on Mac 4: rules are loaded into the anchor and take effect at once; rollback is only `sudo pfctl -a com.apple/nova -F rules`, which leaves pf enabled as it was.

### (template kept for reference)
`sudo pfctl -E` prints a token. Record it here when it is issued:

| Date | Token | Loaded file |
|---|---|---|
| | | |

## Rollback (in this order)
```
sudo pfctl -a com.apple/nova -F rules      # flush only our anchor's rules
sudo pfctl -X <token>                      # release our enable reference
sudo pfctl -a com.apple/nova -sr           # expect: empty
sudo pfctl -s info                         # expect: same status as the baseline
```
Lost token: `sudo pfctl -s References` lists it.
Last resort: a reboot clears the anchor (assumption, to be confirmed).

## Never run
`pfctl -f <file>` without `-a com.apple/nova` · `pfctl -a com.apple -f …` · `pfctl -F …` without `-a` ·
`pfctl -a com.apple/nova -F all` (also flushes the system-wide state table) · `pfctl -F states` · `pfctl -k` ·
`pfctl -d` · `pfctl -e` · `pfctl -z` · `pfctl -f /etc/pf.conf`
