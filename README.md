# ediop3DS
A DDoS tool in bash using a user agents list with 90 million user agents. and 100k of each are used to all attacks

btw http_flood.py and syn_flood.py aren't required by the script

use them separated if you want.

steps to run and requirements.

install these first.

sudo apt update && sudo apt install -y curl nmap hping3 bc net-tools && sudo sysctl -w net.ipv4.ping_group_range="0 2147483647" && pip3 install scapy

hping3 is required for some attacks I couldn't make.

now to run this tool

git clone https://github.com/ediop3SquadALT/ediop3DS

cd ediop3DS

bash ediop3DS.sh -h 

for help.
