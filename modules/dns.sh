#!/bin/bash

TARGET="$1"

echo -e "\033[1;33m[*] DNS Enumeration on $TARGET\033[0m"

# Try Zone Transfer
echo -e "\033[1;33m[*] Trying Zone Transfer...\033[0m"
host -l "$TARGET" "$TARGET" 2>/dev/null | head -10
