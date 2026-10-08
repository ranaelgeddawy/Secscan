#!/bin/bash

TARGET="$1"
REPORT_DIR="${2:-reports}"
SCAN_DATE="${3:-$(date +%Y-%m-%d_%H-%M-%S)}"
MODULE_OUTPUT="$REPORT_DIR/ftp.txt"

{
    echo -e "\033[1;33m[*] FTP Enumeration on $TARGET\033[0m"

    echo -e "\033[1;33m[*] Checking Anonymous Login...\033[0m"
    if timeout 5 bash -c "echo -e 'USER anonymous\nPASS anonymous\nQUIT' | nc -nv $TARGET 21" 2>/dev/null | grep -q "230"; then
        echo -e "\033[0;32m[+] Anonymous FTP Login Allowed\033[0m"
        echo ""
        echo "FINDING: Anonymous FTP Login Allowed"
        echo "EVIDENCE: FTP server responded with code 230 for anonymous login"
        echo "RISK: Anyone can access FTP server without credentials."
        echo "RECOMMENDATION: Disable anonymous FTP access."
    else
        echo -e "\033[0;31m[!] Anonymous FTP Login Not Allowed\033[0m"
    fi
} | tee "$MODULE_OUTPUT"
