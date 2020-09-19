# VPN-iOS
VPN app for redirecting DSN traffic in iOS devices


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



