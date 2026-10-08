#!/bin/bash

TARGET="$1"
REPORT_DIR="${2:-reports}"
SCAN_DATE="${3:-$(date +%Y-%m-%d_%H-%M-%S)}"
MODULE_OUTPUT="$REPORT_DIR/smb.txt"

{
    echo -e "\033[1;33m[*] SMB Enumeration on $TARGET\033[0m"

    echo -e "\033[1;33m[*] Listing SMB shares...\033[0m"
    SHARES=$(smbclient -L "//$TARGET" -N 2>/dev/null)

    if echo "$SHARES" | grep -qE "^\s+(print|tmp|opt|IPC)" ; then
        echo "$SHARES"
        echo ""
        echo "FINDING: Anonymous SMB Share Access"
        echo "EVIDENCE: SMB shares accessible without authentication"
        echo "RISK: Anyone can list and possibly access SMB shares."
        echo "RECOMMENDATION: Disable anonymous SMB access and require authentication."
    fi
} | tee "$MODULE_OUTPUT"
