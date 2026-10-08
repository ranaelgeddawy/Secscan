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
SCAN_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_DIR="reports"
MODULES_DIR="$REPORT_DIR/modules"

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
    for tool in nmap ping curl nc smbclient host; do
        if ! command -v $tool &>/dev/null; then
            echo -e "${RED}[!] $tool is not installed${NC}"
            exit 1
        fi
    done

    for tool in smtp-user-enum gobuster nikto; do
        if ! command -v $tool &>/dev/null; then
            echo -e "${YELLOW}[*] Optional: $tool not found (some checks will be skipped)${NC}"
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
    nmap -sV -T4 -oN "$REPORT_DIR/scan.txt" "$TARGET" >/dev/null 2>&1
    echo -e "${GREEN}[+] Nmap scan completed${NC}"
}

extract_ports() {
    echo -e "${YELLOW}[*] Extracting open ports...${NC}"
    OPEN_PORTS=$(grep -E "^[0-9]+/tcp" "$REPORT_DIR/scan.txt" | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
    echo -e "${GREEN}[+] Open ports: $OPEN_PORTS${NC}"
}

decide_services() {
    echo -e "${YELLOW}[*] Deciding what to enumerate...${NC}"

    mkdir -p "$MODULES_DIR"

    if grep -qE "21/tcp.*open" "$REPORT_DIR/scan.txt"; then
        echo -e "${GREEN}[+] FTP detected${NC}"
        bash modules/ftp.sh "$TARGET" "$MODULES_DIR" "$SCAN_DATE"
    fi

    if grep -qE "22/tcp.*open" "$REPORT_DIR/scan.txt"; then
        echo -e "${GREEN}[+] SSH detected${NC}"
        bash modules/ssh.sh "$TARGET" "$MODULES_DIR" "$SCAN_DATE"
    fi

    if grep -qE "(139|445)/tcp.*open" "$REPORT_DIR/scan.txt"; then
        echo -e "${GREEN}[+] SMB detected${NC}"
        bash modules/smb.sh "$TARGET" "$MODULES_DIR" "$SCAN_DATE"
    fi

    if grep -qE "25/tcp.*open" "$REPORT_DIR/scan.txt"; then
        echo -e "${GREEN}[+] SMTP detected${NC}"
        bash modules/smtp.sh "$TARGET" "$MODULES_DIR" "$SCAN_DATE"
    fi

    if grep -qE "(80|8080|8000)/tcp.*open" "$REPORT_DIR/scan.txt"; then
        echo -e "${GREEN}[+] HTTP detected${NC}"
        bash modules/http.sh "$TARGET" "$MODULES_DIR" "$SCAN_DATE"
    fi

    if grep -qE "53/tcp.*open" "$REPORT_DIR/scan.txt"; then
        echo -e "${GREEN}[+] DNS detected${NC}"
        bash modules/dns.sh "$TARGET" "$MODULES_DIR" "$SCAN_DATE"
    fi
}

generate_report() {
    echo -e "${YELLOW}[*] Generating final report...${NC}"
    mkdir -p "$REPORT_DIR"

    # findings.txt (Findings from modules only)
    {
        echo "============================================="
        echo "  Security Assessment - Findings"
        echo "============================================="
        echo ""
        echo "Target: $TARGET"
        echo "Date: $SCAN_DATE"
        echo ""
        echo "--- Findings ---"
        echo ""

        FOUND=0
        for module_file in "$MODULES_DIR"/*.txt; do
            if [ -f "$module_file" ] && grep -q "^FINDING:" "$module_file"; then
                grep -A 4 "^FINDING:" "$module_file"
                echo ""
                FOUND=1
            fi
        done

        if [ "$FOUND" -eq 0 ]; then
            echo "No findings."
            echo ""
        fi
    } > "$REPORT_DIR/findings.txt"

    # summary.txt
    {
        echo "============================================="
        echo "  Security Assessment Report"
        echo "============================================="
        echo ""
        echo "Target: $TARGET"
        echo "Date: $SCAN_DATE"
        echo "Open Ports: $OPEN_PORTS"
        echo ""
        echo "See findings.txt for detailed findings."
        echo "See scan.txt for full Nmap scan."
    } > "$REPORT_DIR/summary.txt"

    echo -e "${GREEN}[+] Reports saved to: $REPORT_DIR/${NC}"
}

generate_html_report() {
    echo -e "${YELLOW}[*] Generating HTML report...${NC}"
    HTML_FILE="$REPORT_DIR/report.html"

    {
        echo "<!DOCTYPE html>"
        echo "<html><head><title>Security Report</title>"
        echo "<style>"
        echo "body{font-family:Arial;margin:40px;background:#f5f5f5;}"
        echo "h1{color:#333;} .finding{background:#fff3cd;padding:15px;margin:15px 0;border-left:4px solid #ffc107;border-radius:4px;}"
        echo ".risk{color:#dc3545;} .rec{color:#28a745;} .evidence{color:#666;font-size:0.9em;}"
        echo "</style></head><body>"
        echo "<h1>Security Assessment Report</h1>"
        echo "<p><b>Target:</b> $TARGET</p>"
        echo "<p><b>Date:</b> $SCAN_DATE</p>"
        echo "<p><b>Open Ports:</b> $OPEN_PORTS</p>"
        echo "<h2>Findings</h2>"

        FOUND=0
        for module_file in "$MODULES_DIR"/*.txt; do
            if [ -f "$module_file" ] && grep -q "^FINDING:" "$module_file"; then
                while IFS= read -r line; do
                    case "$line" in
                        FINDING:*) echo "<div class='finding'><h3>${line#FINDING: }</h3>" ;;
                        EVIDENCE:*) echo "<p class='evidence'><b>Evidence:</b> ${line#EVIDENCE: }</p>" ;;
                        RISK:*) echo "<p class='risk'><b>Risk:</b> ${line#RISK: }</p>" ;;
                        RECOMMENDATION:*) echo "<p class='rec'><b>Recommendation:</b> ${line#RECOMMENDATION: }</p></div>" ;;
                    esac
                done < <(grep -A 4 "^FINDING:" "$module_file")
                FOUND=1
            fi
        done

        if [ "$FOUND" -eq 0 ]; then
            echo "<p>No findings.</p>"
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

if [ -d "reports" ]; then
    echo -e "${YELLOW}[*] Cleaning old reports...${NC}"
    rm -rf reports/*
fi

run_nmap
extract_ports
decide_services
generate_report
generate_html_report
