# Video script: Setup, Configuration and Failure Demonstration (Team Nova)

About 5 minutes, spoken over `Team_Nova_Demo_Report.pdf`.

| Time | Speaker | Pages | Section |
|---|---|---|---|
| 0:00 to 2:00 | Kanishk Sharma | 1 to 3 | Team intro and setup flow |
| 2:00 to 3:00 | Adarsh Vashistha | 4 to 5 | How the configuration works: DNS and backends |
| 3:00 to 4:00 | Deepanshu | 6 to 7 | How the configuration works: nginx, certificate, one full request |
| 4:00 to 5:00 | Hrishabh Prajapati | 8 to 9 | Failure demonstration and closing |

## Part 1: Kanishk Sharma (pages 1 to 3, 2 minutes)

### Page 1: Cover (about 20 seconds)

Hello everyone. We are Team Nova, and this is our project, the Private Network Service Platform. I am Kanishk Sharma, and I built Backend A on Mac 3. Hrishabh runs the DNS server on Mac 1. Deepanshu runs the nginx edge server on Mac 2. Adarsh built Backend B on Mac 4, which is also our test client.

### Page 2: Team and what we built (about 40 seconds)

We built a small private web service on four MacBooks that share one Wi-Fi network. Please look at Figure 1. A user opens https://app.nova.test. First, the DNS server on Mac 1 answers that this name means 10.7.7.58. Second, the user connects to that address, which is Mac 2, over HTTPS. Third, Mac 2 passes the request to Backend A or Backend B and sends the reply back. We set the system up from the inside out: backends first, then DNS and nginx, and the clients last.

### Page 3: Six setup steps (about 60 seconds)

This page shows our six setup steps. The commands are on the left, and the screenshot on the right proves that the step worked. Step one: all four Macs join the same Wi-Fi and ping each other with zero percent packet loss. Step two: we start the two backends with node server.js, on ports 3001 and 3002. Step three: we start dnsmasq on Mac 1, on UDP port 53. Step four: on Mac 2, mkcert creates the certificate and nginx starts on port 443. Step five: every client is told to use Mac 1 as its DNS server and to trust our certificate authority. Step six: we send six requests. All return 200 OK, and the backends answer in turn. Now Adarsh will explain the configuration.

## Part 2a: Adarsh Vashistha (pages 4 to 5, 1 minute)

### Page 4: DNS server on Mac 1 (about 30 seconds)

Thank you, Kanishk. I am Adarsh. The DNS server needs only three lines, shown in Figure 8. The first two say that app.nova.test and api.nova.test point to 10.7.7.58, which is Mac 2. The third makes dnsmasq listen on the Wi-Fi address, so that other Macs can ask it. In Figure 9, dig returns 10.7.7.58, and the SERVER line shows that the answer came from Mac 1.

### Page 5: Backends on Mac 3 and Mac 4 (about 30 seconds)

Each backend has a few settings in its server.js file. HOST is 0.0.0.0, so other Macs can connect. PORT is 3001 for Backend A and 3002 for Backend B. Every reply carries a header called X-Backend, with the value A or B, so we can see which backend answered. The home page may be cached for 60 seconds. Figure 10 shows Backend A replying with these headers. Over to Deepanshu.

## Part 2b: Deepanshu (pages 6 to 7, 1 minute)

### Page 6: Edge server and certificate (about 30 seconds)

Thank you, Adarsh. I am Deepanshu. nginx on Mac 2 reads one file, shown in Figure 11. The upstream block lists the two backends. nginx uses round robin, so they take turns. The line listen 443 ssl accepts HTTPS, using the certificate we made with mkcert. The proxy_pass line forwards every request to the backends. Figure 12 shows two requests: one answered by Backend B and one by Backend A.

### Page 7: One request from start to finish (about 30 seconds)

Figure 13 is one real request from Mac 4, run without the -k flag. Each part of the output comes from a setting. The name becomes 10.7.7.58: that is the DNS record. The connection goes to port 443 and uses TLS 1.3: that is nginx and the certificate. The certificate is verified. And X-Backend B shows which backend replied. Now Hrishabh will show the failures.

## Part 3: Hrishabh Prajapati (pages 8 to 9, 1 minute)

### Page 8: Failure 1, wrong DNS server (about 25 seconds)

Thank you, Deepanshu. I am Hrishabh. We broke one setting at a time, on purpose. Failure one: on Mac 4, we changed the DNS server to the public server 8.8.8.8. dig returned NXDOMAIN, and curl could not resolve the host. But ping to Mac 2 still worked. So DNS and IP are independent.

### Page 9: Failure 2, wrong DNS record, and closing (about 35 seconds)

Failure two: on Mac 1, we changed the DNS record to a wrong address, 10.7.20.99. DNS still answered with no error, but the answer was wrong, and Mac 2 was still running. So DNS is only a directory. After each test we restored the setting and checked again. The table lists three more scenarios that we have not captured yet, with their expected results: one backend stopped, both backends stopped, and a wrong port. That is our project. Thank you.
