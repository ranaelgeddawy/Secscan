#!/bin/bash

TARGET="$1"
REPORT_DIR="${2:-reports}"
SCAN_DATE="${3:-$(date +%Y-%m-%d_%H-%M-%S)}"
MODULE_OUTPUT="$REPORT_DIR/dns.txt"

{
    echo -e "\033[1;33m[*] DNS Enumeration on $TARGET\033[0m"

    echo -e "\033[1;33m[*] Trying Zone Transfer...\033[0m"
    ZONE=$(host -l "$TARGET" "$TARGET" 2>/dev/null | head -10)

    if echo "$ZONE" | grep -qE "has address|has IPv6|IN\s+SOA|IN\s+NS"; then
        echo ""
        echo "FINDING: DNS Zone Transfer Allowed"
        echo "EVIDENCE: Zone transfer returned records for $TARGET"
        echo "RISK: Attackers can map the entire DNS zone."
        echo "RECOMMENDATION: Restrict zone transfers to authorized servers."
    fi
} | tee "$MODULE_OUTPUT"
