#!/bin/bash

TARGET="$1"

echo -e "\033[1;33m[*] SSH Enumeration on $TARGET\033[0m"

# Get SSH version/banner
echo -e "\033[1;33m[*] SSH Banner...\033[0m"
timeout 5 bash -c "echo | nc -nv $TARGET 22" 2>&1 | grep "SSH-"
