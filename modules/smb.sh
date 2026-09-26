#!/bin/bash

TARGET="$1"

echo -e "\033[1;33m[*] SMB Enumeration on $TARGET\033[0m"

echo -e "\033[1;33m[*] Listing SMB shares...\033[0m"
smbclient -L "//$TARGET" -N 2>/dev/null

echo -e "\033[1;33m[*] Checking 'tmp' share...\033[0m"
smbclient "//$TARGET/tmp" -N -c "ls" 2>/dev/null | grep -E "^\s+[a-zA-Z]" | head -3
