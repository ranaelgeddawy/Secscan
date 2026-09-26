# secscan.sh - Bash Security Assessment Tool

## Description
A mini automated security assessment framework in Bash.

## Features
- Reconnaissance (ping check)
- Port scanning (Nmap)
- Service enumeration (FTP, SSH, SMB, SMTP, DNS, HTTP)
- Findings with evidence, risk, and recommendations
- Report generation

## Requirements
- Nmap
- smbclient
- smtp-user-enum
- gobuster (optional)
- nikto (optional)

## Usage
./secscan.sh <TARGET>

## Example
./secscan.sh 192.168.32.130

## Modules
| Module | Service |
|--------|---------|
| modules/ftp.sh | FTP Anonymous Login |
| modules/smb.sh | SMB Share Enumeration |
| modules/smtp.sh | SMTP Open Relay + User Enum |
| modules/dns.sh | DNS Zone Transfer |
| modules/http.sh | HTTP Headers + Gobuster + Nikto |
| modules/ssh.sh | SSH Banner Check |

## Reports
Reports are saved in `reports/` folder:
- `nmap_<date>.txt` (Nmap scan)
- `summary_<date>.txt` (Full report)

## Author
Rana Elgeddawy
