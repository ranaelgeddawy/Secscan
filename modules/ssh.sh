
#!/bin/bash

TARGET="$1"
REPORT_DIR="${2:-reports}"
SCAN_DATE="${3:-$(date +%Y-%m-%d_%H-%M-%S)}"
MODULE_OUTPUT="$REPORT_DIR/ssh.txt"

{
    echo -e "\033[1;33m[*] SSH Enumeration on $TARGET\033[0m"

    echo -e "\033[1;33m[*] SSH Banner...\033[0m"
    BANNER=$(timeout 5 bash -c "echo | nc -nv $TARGET 22" 2>&1 | grep "SSH-")

    if [ -n "$BANNER" ]; then
        echo "$BANNER"
        echo ""
        echo "FINDING: SSH Version Disclosure"
        echo "EVIDENCE: $BANNER"
        echo "RISK: Attackers can identify vulnerable SSH versions."
        echo "RECOMMENDATION: Update SSH to the latest version."
    fi
} | tee "$MODULE_OUTPUT"
