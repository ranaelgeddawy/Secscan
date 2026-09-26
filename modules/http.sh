#!/bin/bash

TARGET="$1"

echo -e "\033[1;33m[*] HTTP Enumeration on $TARGET\033[0m"

echo -e "\033[1;33m[*] HTTP Headers...\033[0m"
curl -sI "http://$TARGET" | grep -E "Server|X-Powered|Content-Type"

echo -e "\033[1;33m[*] Checking robots.txt...\033[0m"
curl -s "http://$TARGET/robots.txt" | head -3

if command -v gobuster &>/dev/null; then
    echo -e "\033[1;33m[*] Running Gobuster...\033[0m"
    gobuster dir -u "http://$TARGET" -w /usr/share/wordlists/dirb/common.txt -q 2>/dev/null | head -15
fi

if command -v nikto &>/dev/null; then
    echo -e "\033[1;33m[*] Running Nikto (fast)...\033[0m"
    nikto -h "http://$TARGET" -nointeractive -maxtime 10s -Tuning 1 2>/dev/null | grep -E "^\+" | head -5
fi

# Add test for HTTP methods
echo -e "\033[1;33m[*] Testing HTTP methods...\033[0m"
curl -s -X OPTIONS "http://$TARGET" -i | grep "Allow:"
