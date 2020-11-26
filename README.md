# VPN-iOS
VPN app for redirecting DNS traffic in iOS devices

# It's based on SimpleVPN (https://github.com/gordinmitya/SimpleVPN) with some changes:

1. Created `VPNConstants.swift` and `DNSConstants.h/m` files with predefined values of our VPN and DNS server (address, username, password).
2. Refactored `VPNManager`
3. New UI (removed unneeded fields and added switches)
4. Added Packet Tunnel Network Extension which proxies packets to DNSCrypt
5. Added DNSCrypt library (built for iOS from https://github.com/s-s/dnscloak)
6. DNSCrypt integrated to Network Extension as separate NSThread

# Constants

Change `VPNConstants.swift` and `DNSConstants.h/m` to according values if you need to change a servers address/username/password or App Group.

# Capabilities

When creating new App IDs (for main app and extension) be sure to add Network Extension Capability, App Group (remember to set its ID to Constants) and Personal VPN (for main app only)

# IKEv2 VPN Server deployment process

Prerequisites: Ubuntu 18.04 LTS, registered domain name.

Make sure that you have you domain name DNS A record pointing to your server's IP address. Check that with https://mxtoolbox.com/SuperTool.aspx or anything like that

## Step 1

Clone the repo https://github.com/jawj/IKEv2-setup

`git clone https://github.com/jawj/IKEv2-setup.git`

## Step 2

Open ports 500 UDP, 4500 UDP and 80 TCP (you can close that after settings, it is needed to verify your address for Let's Encrypt SSL certificate) in your hosting service firewall settings (Azure, AWS, Google Cloud, etc).

## Step 3

Run the script and follow the instructions
https://github.com/jawj/IKEv2-setup#how

## Step 4

You will have .mobileconfig files directed to your email (make sure to check Spam folder). Or you can see it in `/home/created_user_here` folder. `created_user_here` is the name of user that was created in Step 3. You can just `cat` this file, copy it's data and create a `vpn.mobileconfig` file from that or you can download it thorugh `scp` command.

## Step 5

You can install this .mobileconfig file to any iOS/macOS/Android device (be sure to input the correct username and password created in the Step 3) and connect to VPN within the OS and check that it works fine.


# DNSSec (DoH, DNSCrypt) Server deployment process

Prerequisites: Ubuntu 18.04 LTS, Docker. Opened 443, 9100 ports. Based on https://github.com/DNSCrypt/dnscrypt-server-docker

## Step 1

Run command

```
docker run --name=dnscrypt-server -p 443:443/udp -p 443:443/tcp -p 9100:9100/tcp \
--restart=unless-stopped \
-v /etc/dnscrypt-server/keys:/opt/encrypted-dns/etc/keys \
jedisct1/dnscrypt-server init -N dnsserver -E '94.245.109.120:443' -M '0.0.0.0:9100'
```

Where `94.245.109.120` is your server IP address and `dnsserver` is you server name (it can be anything you want)

## Step 2

You will get a response like this

```
Provider name: [2.dnscrypt-cert.dnsserver]
[INFO ] Dropping privileges
[INFO ] State file [/opt/encrypted-dns/etc/keys/state/encrypted-dns.state] found; using existing provider key
[INFO ] Public server address: 94.245.109.120:443
[INFO ] Provider public key: 2ed5decd5e9c26b1898b0cbf61c2b61a2d2a5b61b3b17473b0fd432b0ce84db5
[INFO ] Provider name: 2.dnscrypt-cert.dnsserver
[INFO ] DNS Stamp: sdns://AQcAAAAAAAAAEjk0LjI0NS4xMDkuMTIwOjQ0MyAu1d7NXpwmsYmLDL9hwrYaLSpbYbOxdHOw_UMrDOhNtRkyLmRuc2NyeXB0LWNlcnQuZG5zc2VydmVy
```

Copy DNS Stamp value (`AQcAAAAAAAAAEjk0LjI0NS4xMDkuMTIwOjQ0MyAu1d7NXpwmsYmLDL9hwrYaLSpbYbOxdHOw_UMrDOhNtRkyLmRuc2NyeXB0LWNlcnQuZG5zc2VydmVy`). This is your server stamp, you can insert it in `DNSConstants.m` or in any `dnscrypt.toml` config file if you need to run `dnscrypt-proxy` on another device or platform.


You can check stats for server on `YOUR_IP:9100/metrics` (it is Prometheus optimized, but it's readable in browser).



## DNSCloak for iOS
iOS GUI and wrapper for dnscrypt-proxy 2.

Uses Apache Cordova as app platform & Framework7 as UI.

Available on the App Store.

# Master Branch
This branch works with Xcode 10.0 and supports iOS 10.0+.

# Build Instructions for Master
1. Install the latest Xcode developer tools from Apple.
2. Install Node.js & npm.
3. Install golang. 1.12+ is required for TLS 1.3 support.
4. Clone the repository:
    `git clone https://github.com/s-s/dnscloak.git`
5. Pull in the project dependencies:
    ```cd dnscloak
       npm install && npm install --only=dev```
6. Build framework, (re)build www folder for cordova and prepare project for Xcode:
    `npm run build`
7. Open platforms/ios/DNSCryptApp.xcworkspace in Xcode.
    `Build the DNSCryptApp scheme.`

