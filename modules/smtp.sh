#!/bin/bash

TARGET="$1"
REPORT_DIR="${2:-reports}"
SCAN_DATE="${3:-$(date +%Y-%m-%d_%H-%M-%S)}"
MODULE_OUTPUT="$REPORT_DIR/smtp.txt"

{
    echo -e "\033[1;33m[*] SMTP Enumeration on $TARGET\033[0m"

    echo -e "\033[1;33m[*] Checking Open Relay...\033[0m"
    RELAY=$(nmap -p 25 --script smtp-open-relay "$TARGET" 2>/dev/null)

    if echo "$RELAY" | grep -q "Server is an open relay"; then
        echo "$RELAY"
        echo ""
        echo "FINDING: SMTP Open Relay"
        echo "EVIDENCE: Nmap smtp-open-relay script detected open relay"
        echo "RISK: Server can be abused to send spam."
        echo "RECOMMENDATION: Restrict SMTP relay to authorized hosts."
    fi

    if command -v smtp-user-enum &>/dev/null; then
        echo -e "\033[1;33m[*] Enumerating users...\033[0m"
        USERS=$(smtp-user-enum -M VRFY -U /usr/share/wordlists/metasploit/unix_users.txt -t "$TARGET" -w 1 2>/dev/null | grep -E "^\s*[0-9]+:")
        if [ -n "$USERS" ]; then
            echo "$USERS"
            echo ""
            echo "FINDING: SMTP User Enumeration Possible"
            echo "EVIDENCE: VRFY command allows user enumeration"
            echo "RISK: Attackers can enumerate valid email addresses."
            echo "RECOMMENDATION: Disable VRFY command in Postfix."
        fi
    fi
} | tee "$MODULE_OUTPUT"
