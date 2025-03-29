# ediop3DS
A DoS tool in bash. Simulating DDoS every tool that claims to be a DDoS is a DoS tool Simulating DDoS

steps to run and requirements.

install these first.

sudo apt update && sudo apt install -y curl nmap hping3 bc net-tools && sudo sysctl -w net.ipv4.ping_group_range="0 2147483647"

hping3 is required for some attacks I couldn't make.

now to run this tool

git clone https://github.com/ediop3SquadALT/ediop3DS

cd ediop3DS

bash ediop3DS.sh -h 

for help.
