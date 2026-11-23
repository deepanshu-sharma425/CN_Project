# IP inventory

Filled in during **S0**. Until every row below is VERIFIED, no command or configuration may use these addresses. Historical values are for reference only.

Network (Phase 1): 10.7.0.0/19, gateway 10.7.0.1. Re-check in S0.

| Mac | Owner | Current IPv4 (S0) | Interface | MAC address | Gateway | Wi-Fi service name | DNS list (before CP1) | Stealth mode | pf status | Verified at |
|---|---|---|---|---|---|---|---|---|---|---|
| Mac 1 | Hrishabh | NOT VERIFIED | | | | | | | | |
| Mac 2 | Deepanshu | NOT VERIFIED | | | | | | | | |
| Mac 3 | Kanishk | NOT VERIFIED | | | | | | | | |
| Mac 4 | Adarsh | NOT VERIFIED | | | | | | | | |

## Historical values (do not use in commands)

| Mac | Phase 1 (5 Oct 2026) | Other observations |
|---|---|---|
| Mac 1 | 10.7.8.113 | No ping reply from Mac 3 on 23 Nov |
| Mac 2 | 10.7.7.58 | No ping reply from Mac 3 on 23 Nov |
| Mac 3 | 10.7.19.171 (earlier 10.7.2.229) | 10.7.1.218 seen on 23 Nov |
| Mac 4 | 10.7.20.75 | No ping reply from Mac 3 on 23 Nov |

## Placeholders used in prompts and configs

`<MAC1_IP>` `<MAC2_IP>` `<MAC3_IP>` `<MAC4_IP>` = the verified column above. `<WIFI_SERVICE>` = each Mac's service name from `networksetup -listallnetworkservices`.
