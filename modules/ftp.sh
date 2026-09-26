#!/bin/bash

TARGET="$1"

echo -e "\033[1;33m[*] FTP Enumeration on $TARGET\033[0m"

# Check for Anonymous Login
echo -e "\033[1;33m[*] Checking Anonymous Login...\033[0m"
if timeout 5 bash -c "echo -e 'USER anonymous\nPASS anonymous\nQUIT' | nc -nv $TARGET 21" 2>/dev/null | grep -q "230"; then
    echo -e "\033[0;32m[+] Anonymous FTP Login Allowed\033[0m"
else
    echo -e "\033[0;31m[!] Anonymous FTP Login Not Allowed\033[0m"
fi
