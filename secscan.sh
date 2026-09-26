#!/bin/bash

# =============================================
# secscan.sh - Bash Security Assessment Tool
# =============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
TARGET=""
REPORT_DIR="reports"
SCAN_DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# =============================================
# Functions
# =============================================

banner() {
    echo "============================================="
    echo "  secscan.sh - Security Assessment Tool"
    echo "============================================="
}

usage() {
    echo "Usage: $0 <TARGET>"
    echo "Example: $0 192.168.1.100"
    exit 1
}

check_deps() {
    for tool in nmap ping; do
        if ! command -v $tool &>/dev/null; then
            echo -e "${RED}[!] $tool is not installed${NC}"
            exit 1
        fi
    done
    echo -e "${GREEN}[+] All dependencies found${NC}"
}

check_target() {
    echo -e "${YELLOW}[*] Checking if target is reachable...${NC}"
    if ping -c 2 "$TARGET" &>/dev/null; then
        echo -e "${GREEN}[+] Target is reachable${NC}"
        return 0
    else
        echo -e "${RED}[!] Target is unreachable${NC}"
        exit 1
    fi
}

run_nmap() {
    echo -e "${YELLOW}[*] Running Nmap scan...${NC}"
    mkdir -p "$REPORT_DIR"
    nmap -sV -sC -oN "$REPORT_DIR/nmap_$SCAN_DATE.txt" "$TARGET" >/dev/null 2>&1
    echo -e "${GREEN}[+] Nmap scan completed${NC}"
}

extract_ports() {
    echo -e "${YELLOW}[*] Extracting open ports...${NC}"
    OPEN_PORTS=$(grep -E "^[0-9]+/tcp" "$REPORT_DIR/nmap_$SCAN_DATE.txt" | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
    echo -e "${GREEN}[+] Open ports: $OPEN_PORTS${NC}"
}

decide_services() {
    echo -e "${YELLOW}[*] Deciding what to enumerate...${NC}"

    if grep -q "ftp" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
        echo -e "${GREEN}[+] FTP detected${NC}"
        bash modules/ftp.sh "$TARGET"
    fi

    if grep -q "smb" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
        echo -e "${GREEN}[+] SMB detected${NC}"
        bash modules/smb.sh "$TARGET"
    fi

    if grep -q "smtp" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
        echo -e "${GREEN}[+] SMTP detected${NC}"
        bash modules/smtp.sh "$TARGET"
    fi

    if grep -q "http" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
        echo -e "${GREEN}[+] HTTP detected${NC}"
        bash modules/http.sh "$TARGET"
    fi

    if grep -q "ssh" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
        echo -e "${GREEN}[+] SSH detected${NC}"
        bash modules/ssh.sh "$TARGET"
    fi

    if grep -q "domain" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
        echo -e "${GREEN}[+] DNS detected${NC}"
        bash modules/dns.sh "$TARGET"
    fi
}

generate_report() {
    echo -e "${YELLOW}[*] Generating final report...${NC}"
    mkdir -p "$REPORT_DIR"

    # 1. findings_<date>.txt (Findings only)
    {
        echo "--- Findings ---"
        echo ""

        if grep -q "Anonymous FTP login allowed" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "[!] Anonymous FTP Login Allowed"
            echo "    Evidence: Nmap shows 'Anonymous FTP login allowed (FTP code 230)'"
            echo "    Risk: Anyone can access FTP server without credentials."
            echo "    Recommendation: Disable anonymous FTP access."
            echo ""
        fi

        if grep -q "message_signing: disabled" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "[!] SMB Signing Disabled"
            echo "    Evidence: Nmap shows 'message_signing: disabled'"
            echo "    Risk: Man-in-the-middle attacks possible."
            echo "    Recommendation: Enable SMB signing."
            echo ""
        fi

        if grep -q "OpenSSH" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "[!] SSH Version Disclosure"
            echo "    Evidence: $(grep 'OpenSSH' "$REPORT_DIR/nmap_$SCAN_DATE.txt" | head -1)"
            echo "    Risk: Attackers can identify vulnerable SSH versions."
            echo "    Recommendation: Update SSH to latest version."
            echo ""
        fi

        if grep -q "Apache" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "[!] HTTP Version Disclosure"
            echo "    Evidence: $(grep 'Apache' "$REPORT_DIR/nmap_$SCAN_DATE.txt" | head -1)"
            echo "    Risk: Information disclosure helps attackers fingerprint the server."
            echo "    Recommendation: Remove version headers from HTTP responses."
            echo ""
        fi

        if grep -q "VRFY" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "[!] SMTP VRFY Enabled"
            echo "    Evidence: Nmap shows 'VRFY' in smtp-commands"
            echo "    Risk: Attackers can enumerate valid email addresses."
            echo "    Recommendation: Disable VRFY command in Postfix."
            echo ""
        fi

        if grep -q "telnet" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "[!] Telnet Service Enabled"
            echo "    Evidence: Nmap shows 'telnet' on port 23"
            echo "    Risk: Telnet sends data in plain text, including credentials."
            echo "    Recommendation: Disable Telnet and use SSH instead."
            echo ""
        fi
    } > "$REPORT_DIR/findings_$SCAN_DATE.txt"

    # 2. summary_<date>.txt (Target + Date + Open Ports only)
    {
        echo "============================================="
        echo "  Security Assessment Report"
        echo "============================================="
        echo ""
        echo "Target: $TARGET"
        echo "Date: $SCAN_DATE"
        echo "Open Ports: $OPEN_PORTS"
        echo ""
        echo "See findings_$SCAN_DATE.txt for detailed findings."
        echo "See nmap_$SCAN_DATE.txt for full Nmap scan."
    } > "$REPORT_DIR/summary_$SCAN_DATE.txt"

    echo -e "${GREEN}[+] Reports saved to: $REPORT_DIR/${NC}"
}

generate_html_report() {
    echo -e "${YELLOW}[*] Generating HTML report...${NC}"
    HTML_FILE="$REPORT_DIR/report_$SCAN_DATE.html"

    {
        echo "<!DOCTYPE html>"
        echo "<html><head><title>Security Report</title>"
        echo "<style>body{font-family:Arial;} .finding{background:#fff3cd;padding:10px;margin:10px;border-left:4px solid #ffc107;}"
        echo ".risk{color:#dc3545;} .rec{color:#28a745;}</style></head><body>"
        echo "<h1>Security Assessment Report</h1>"
        echo "<p><b>Target:</b> $TARGET</p>"
        echo "<p><b>Date:</b> $SCAN_DATE</p>"
        echo "<p><b>Open Ports:</b> $OPEN_PORTS</p>"
        echo "<h2>Findings</h2>"

        if grep -q "Anonymous FTP login allowed" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "<div class='finding'><b>[!] Anonymous FTP Login Allowed</b><br>"
            echo "<span class='risk'>Risk: Anyone can access FTP server without credentials.</span><br>"
            echo "<span class='rec'>Recommendation: Disable anonymous FTP access.</span></div>"
        fi

        if grep -q "message_signing: disabled" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "<div class='finding'><b>[!] SMB Signing Disabled</b><br>"
            echo "<span class='risk'>Risk: Man-in-the-middle attacks possible.</span><br>"
            echo "<span class='rec'>Recommendation: Enable SMB signing.</span></div>"
        fi

        if grep -q "OpenSSH" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "<div class='finding'><b>[!] SSH Version Disclosure</b><br>"
            echo "<span class='risk'>Risk: Attackers can identify vulnerable SSH versions.</span><br>"
            echo "<span class='rec'>Recommendation: Update SSH.</span></div>"
        fi
        if grep -q "Apache" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "<div class='finding'><b>[!] HTTP Version Disclosure</b><br>"
            echo "<span class='risk'>Risk: Information disclosure helps attackers fingerprint the server.</span><br>"
            echo "<span class='rec'>Recommendation: Remove version headers.</span></div>"
        fi

        if grep -q "VRFY" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "<div class='finding'><b>[!] SMTP VRFY Enabled</b><br>"
            echo "<span class='risk'>Risk: Attackers can enumerate valid email addresses.</span><br>"
            echo "<span class='rec'>Recommendation: Disable VRFY in Postfix.</span></div>"
        fi

        if grep -q "telnet" "$REPORT_DIR/nmap_$SCAN_DATE.txt"; then
            echo "<div class='finding'><b>[!] Telnet Service Enabled</b><br>"
            echo "<span class='risk'>Risk: Telnet sends data in plain text, including credentials.</span><br>"
            echo "<span class='rec'>Recommendation: Disable Telnet and use SSH instead.</span></div>"
        fi
        echo "</body></html>"
    } > "$HTML_FILE"
         
    echo -e "${GREEN}[+] HTML report saved to: $HTML_FILE${NC}"
}

# =============================================
# Main
# =============================================

# Help & Version
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
    echo "secscan.sh v1.0"
    exit 0
fi

if [ $# -eq 0 ]; then
    usage
fi

# Multiple targets support
if [ -f "$1" ]; then
    echo -e "${YELLOW}[*] Multiple targets detected${NC}"
    while IFS= read -r line; do
        echo -e "${GREEN}[+] Scanning $line...${NC}"
        bash "$0" "$line"
    done < "$1"
    exit 0
fi

TARGET="$1"

banner
check_deps
check_target

echo -e "${GREEN}[+] Starting assessment on $TARGET${NC}"

run_nmap
extract_ports
decide_services
generate_report
generate_html_report
