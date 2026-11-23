# Presentation script: Phase 1 report (Team Nova)

| Speaker | Pages | What they cover |
|---|---|---|
| Kanishk Sharma | 1 to 5 | Introduction, overview, architecture, request flow, LAN, DNS setup, backends |
| Deepanshu | 6 to 8 | Load balancer, HTTPS and TLS, caching |
| Adarsh Vashistha | 9 to 10 | Packet capture: DNS, TCP, TLS, ports |
| Hrishabh Prajapati | 11 to 12 | Failure demonstrations, summary and closing |

## Part 1: Kanishk Sharma (pages 1 to 5)

### Page 1: Cover

Hello everyone. We are Team Nova, and this is our Phase 1 report for the project Private Network Service Platform. I am Kanishk Sharma, and I built Backend A on Mac 3. Hrishabh set up the DNS server on Mac 1. Deepanshu set up the nginx edge server on Mac 2. Adarsh built Backend B on Mac 4, which is also our test client. I will explain the design, the LAN, the DNS setup and the backends. After that, Deepanshu, Adarsh and Hrishabh will continue.

### Page 2: Overview and architecture

The idea is simple. We built a small private web service on four MacBooks that share one Wi-Fi network. Nothing runs in the cloud. A user types the name app.nova.test. Our own DNS server turns that name into an IP address. The user then connects over HTTPS to our edge server, and the edge server passes the request to one of two backends.

Please look at Figure 1. Mac 1 is the DNS server, at 10.7.8.113 on UDP port 53. Mac 2 is the edge server running nginx, at 10.7.7.58 on TCP port 443. Mac 3 is Backend A on port 3001, and Mac 4 is Backend B on port 3002.

The key point is that the client talks to only two machines: Mac 1 for the name and Mac 2 for the website. It never needs the backend addresses. Those are written only in the nginx configuration, so we can change a backend without touching the client. The last column of the table shows the cloud equivalent: a managed DNS service such as Route 53, and a cloud load balancer.

### Page 3: How one request travels, and Task A (LAN)

This table follows one request in five steps. One: the client asks Mac 1 for the address of app.nova.test, and Mac 1 answers 10.7.7.58. That is DNS over UDP. Two: the client opens a TCP connection to that address on port 443, using the three-way handshake. Three: the client and nginx do the TLS handshake, and the client checks the certificate. Four: the client sends its HTTP request inside the encrypted connection. Five: nginx decrypts it, forwards it to a backend as plain HTTP, and sends the reply back. Under all of this, IP carries the packets and Wi-Fi carries the frames. Notice that DNS only finds the address. After that, the DNS server is not involved.

Task A was the private LAN. All four Macs joined the same Wi-Fi and got their addresses by DHCP. The network is 10.7.0.0/19. The table lists the IP address and MAC address of each Mac. Figure 3 shows Mac 4 pinging the other three Macs with zero percent packet loss. The TTL in the replies is 64, the starting value, so there is no router between the machines. They are on the same LAN.

### Page 4: Task B (DNS setup)

Task B was the private DNS server, which Hrishabh set up on Mac 1 with dnsmasq. Only three lines of configuration matter. The first two say that app.nova.test and api.nova.test point to 10.7.7.58, which is Mac 2. The third makes dnsmasq listen on the Wi-Fi address, so that other Macs can ask it. Figure 4 shows it listening on UDP port 53.

Then the other Macs were set to use 10.7.8.113 as their DNS server. Figures 5 and 6 show the dig command on Mac 4 and Mac 2. There are three things to read. Status NOERROR with the answer 10.7.7.58 means the lookup worked. The SERVER line says 10.7.8.113, so the answer came from our own DNS server. And the TTL is zero, which is the dnsmasq default, so clients do not cache the answer.

### Page 5: Task C (backends)

Task C was the two backends, and Backend A is my part. Each backend is one Node.js file that uses only built-in modules, so there is nothing to install. Both have two endpoints. The root path returns a short page that names the backend. The path /api/status returns JSON saying the backend is ok. Every response also carries a header called X-Backend, with the value A or B. This header is how we prove later which backend answered.

Both servers listen on 0.0.0.0, which means all network interfaces. If they listened only on 127.0.0.1, other Macs could not reach them. Figure 7 shows this as star 3001 and star 3002. Figures 8 and 9 show the backends answering 200 OK with the correct header.

One more detail. The backend logs show requests coming from 10.7.7.58, which is Mac 2, and not from the real client. That is because nginx opens its own connection to the backend. Now Deepanshu will explain the edge server.

## Part 2: Deepanshu (pages 6 to 8)

### Page 6: Task D (reverse proxy and load balancer)

Thank you, Kanishk. I am Deepanshu, and I set up Mac 2. Task D was the reverse proxy and load balancer. Mac 2 runs nginx and is the single entry point, so clients connect only to Mac 2. In the configuration, the upstream block lists the two backends. We did not choose any special method, so nginx uses round robin: one request goes to one backend, and the next request goes to the other. The proxy_pass line forwards the request to that group, and the proxy_set_header lines pass on the original host name and client address. Figure 10 shows nginx listening on port 443. Figure 11 is the proof of load balancing. There are six requests, and the X-Backend header alternates B, A, B, A, B, A.

### Page 7: Task E (HTTPS and TLS)

Task E was HTTPS. TLS ends at nginx, which is called TLS termination. So the link from the client to Mac 2 is encrypted, and the link from Mac 2 to the backends is plain HTTP inside our LAN. We made the certificate with mkcert, which creates a local certificate authority. The certificate is for the name app.nova.test. A client accepts it only if it trusts our certificate authority, so the public CA certificate must be added to the client's trust store. Figure 12 shows curl from Mac 4, run without the -k flag. It shows TLS 1.3, the name matches, and the certificate is verified. The connection uses HTTP/1.1, because HTTP/2 is not switched on in nginx.

### Page 8: Task F (caching)

Task F was caching. The root page does not change, so the backends allow it to be cached for 60 seconds and give it an ETag, which is a fingerprint of the page. The status endpoint is live data, so it is marked no-store. There are three cases. If the client's copy is younger than 60 seconds, it uses the copy and sends nothing. If the copy is older, the client sends the ETag back, and if the page is unchanged the server answers 304 Not Modified with no body. Otherwise the server answers 200 with the full page. nginx only passes these headers through. It does not cache anything itself. Figure 13 shows the headers, Figure 14 shows 200 for an old ETag, and Figure 15 shows 304 when the ETag matches. Our two backends return different pages, so they have different ETags. That is why the request in Figure 15 carries both. Now Adarsh will show the packets.

## Part 3: Adarsh Vashistha (pages 9 to 10)

### Page 9: Task G (DNS, TCP and TLS packets)

Thank you, Deepanshu. I am Adarsh. I built Backend B on Mac 4, and Mac 4 was also our test client. Task G was to capture the real packets, which I did with Wireshark on Mac 4.

First, DNS, in Figure 16. In frame 374, my Mac sends a query to Mac 1 on UDP port 53, asking for the A record of app.nova.test. In frame 377, about 28 milliseconds later, Mac 1 answers 10.7.7.58. The details below the list show the layers of that packet: Ethernet, IP, UDP and then DNS.

Second, the TCP three-way handshake, in Figure 17. The connection goes from port 61935 on my Mac to port 443 on Mac 2. Frame 1228 is the SYN from the client. Frame 1229 is the SYN-ACK from the server. Frame 1230 is the ACK from the client. Only after these three packets does the client send data.

About sequence numbers: each side numbers the bytes it sends, and the Ack number is the next byte the receiver expects. For example, the Client Hello is 1,564 bytes long, so the server replies with Ack 1565. If an acknowledgement does not arrive, the data is sent again. That is how TCP is reliable. The window value tells the sender how much more data the receiver can take, which is flow control.

### Page 10: TLS handshake and ports

Third, the TLS handshake, in Figures 18 and 19. The Client Hello shows the site name app.nova.test in clear text. The Server Hello picks the cipher AES 256 GCM and TLS version 1.3. Wireshark also shows a line saying version TLS 1.2, but that is only for compatibility. After the Server Hello, everything appears as Application Data. In TLS 1.3 even the certificate is encrypted, and so are the HTTP request and response, so Wireshark cannot read them. We can see the HTTP headers only at the two ends, for example with curl.

Finally, the ports table. The server ports are fixed: 53 for DNS and 443 for HTTPS. The client port is temporary and changes for every connection, like 61935 and 63782 here. The client IP and port, together with the server IP and port, identify exactly one connection. Now Hrishabh will show what happens when things break.

## Part 4: Hrishabh Prajapati (pages 11 to 12)

### Page 11: Failure demonstrations

Thank you, Adarsh. I am Hrishabh, and I set up the DNS server on Mac 1. On this page we broke the system on purpose, to see which layer fails and which layers keep working.

Failure one is a wrong DNS server on the client. We changed Mac 4 to use the public server 8.8.8.8 instead of Mac 1. A public server does not know our private name, so dig returns NXDOMAIN and curl says it could not resolve the host. But in the same figure, ping to 10.7.7.58 still works. The name lookup failed, but the network is fine. DNS and IP are independent.

Failure two is a wrong DNS record. On Mac 1, I changed the record for app.nova.test to a wrong address, 10.7.20.99, and restarted dnsmasq. Figure 21 shows that DNS still answers with no error, but the answer is wrong. Mac 2 is still running and still answers ping. So DNS is only a directory. It does not check whether the address is correct. After each test we put the original setting back and checked it again.

Three more scenarios are in the table. We have not captured screenshots for them yet, so the table gives the expected result, and we will show them on the live system. If one backend is stopped, nginx sends every request to the other one and the client still gets 200. If both are stopped, nginx returns 502 Bad Gateway. If the client uses a wrong port, ping still works but the connection is refused or times out.

### Page 12: Summary and closing

This page is our summary. The Phase 1 goal is met: a client resolves app.nova.test through our own DNS server, connects over HTTPS without a certificate warning, and gets answers from both backends. The table lists which figures prove each task.

We also state our limits. Addresses come from DHCP and can change. HTTP/2 is not enabled. The certificate covers only app.nova.test. And Mac 1 and Mac 2 are each a single point of failure.

In Phase 2 we will extend the same setup with a backup DNS server, a short DNS TTL, firewall rules for the backends, backend failover and a standby edge server. That is our Phase 1 report. Thank you. We are happy to take your questions.
