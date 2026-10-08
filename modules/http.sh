#!/bin/bash

TARGET="$1"
REPORT_DIR="${2:-reports}"
SCAN_DATE="${3:-$(date +%Y-%m-%d_%H-%M-%S)}"
MODULE_OUTPUT="$REPORT_DIR/http.txt"

{
    echo -e "\033[1;33m[*] HTTP Enumeration on $TARGET\033[0m"

    echo -e "\033[1;33m[*] HTTP Headers...\033[0m"
    HEADERS=$(curl -sI "http://$TARGET" | grep -E "Server|X-Powered|Content-Type")
    echo "$HEADERS"

    if echo "$HEADERS" | grep -qE "Apache/[0-9]|nginx/[0-9]"; then
        echo ""
        echo "FINDING: HTTP Version Disclosure"
        echo "EVIDENCE: $HEADERS"
        echo "RISK: Information disclosure helps attackers fingerprint the server."
        echo "RECOMMENDATION: Remove version headers from HTTP responses."
    fi

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

    echo -e "\033[1;33m[*] Testing HTTP methods...\033[0m"
    METHODS=$(curl -s -X OPTIONS "http://$TARGET" -i | grep "Allow:")
    if echo "$METHODS" | grep -qE "PUT|DELETE|TRACE"; then
        echo "$METHODS"
        echo ""
        echo "FINDING: Dangerous HTTP Methods Enabled"
        echo "EVIDENCE: $METHODS"
        echo "RISK: Methods like PUT/DELETE/TRACE can lead to file upload or XST attacks."
        echo "RECOMMENDATION: Disable unnecessary HTTP methods."
    fi
} | tee "$MODULE_OUTPUT"
