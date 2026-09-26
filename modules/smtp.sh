#!/bin/bash

TARGET="$1"

echo -e "\033[1;33m[*] SMTP Enumeration on $TARGET\033[0m"

# Check for Open Relay
echo -e "\033[1;33m[*] Checking Open Relay...\033[0m"
nmap -p 25 --script smtp-open-relay "$TARGET" 2>/dev/null

# Enumerate users (if smtp-user-enum is installed)
if command -v smtp-user-enum &>/dev/null; then
    echo -e "\033[1;33m[*] Enumerating users...\033[0m"
    smtp-user-enum -M VRFY -U /usr/share/wordlists/metasploit/unix_users.txt -t "$TARGET" -w 1 2>/dev/null | grep -E "^\s*[0-9]+:"
fi
