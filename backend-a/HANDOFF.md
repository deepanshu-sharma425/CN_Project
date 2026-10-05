# Message for the team (copy and send)

Backend A is up on Mac 3.

- Upstream: 10.7.2.229:3001, plain HTTP
- Endpoints: / and /api/status
- Every response has the header X-Backend: A
- / is cacheable for 60 s (Cache-Control: public, max-age=60, plus ETag; a matching If-None-Match returns 304)
- /api/status is Cache-Control: no-store

Deepanshu: please add 10.7.2.229:3001 as an nginx upstream. nginx passes X-Backend, Cache-Control and ETag through by default, so nothing needs to be stripped or added.

Adarsh: please use the same paths on Backend B with X-Backend: B.

For the load-balancing demo use curl, not a browser, because a browser will cache / for 60 s and hide the A/B alternation.

To prove LAN access I need one of you to run these on your own Mac and send me a screenshot:

    ipconfig getifaddr en0
    curl -si http://10.7.2.229:3001/
    curl -si http://10.7.2.229:3001/api/status
