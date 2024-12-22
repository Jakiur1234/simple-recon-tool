#!/usr/bin/env bash

# Automated Recon Tool with Cross-Platform Support (Linux and macOS)

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # Reset color

# Detect operating system
detect_os() {
    case "$OSTYPE" in
        linux-gnu*) echo "linux" ;;
        darwin*) echo "macos" ;;
        *) echo "unsupported" ;;
    esac
}

# Install dependencies
install_dependencies() {
    local os="$1"
    local tools=("nmap" "whois")

    if [[ "$os" == "linux" ]]; then
        tools+=("dnsutils")
        echo -e "${GREEN}[+] Detected Linux. Installing dependencies...${NC}"
        sudo apt update -y
        for tool in "${tools[@]}"; do
            if ! command -v "$tool" &> /dev/null; then
                echo -e "${GREEN}[+] Installing $tool...${NC}"
                sudo apt install -y "$tool"
            else
                echo -e "${GREEN}[+] $tool is already installed.${NC}"
            fi
        done
        if ! command -v pip3 &> /dev/null; then
            echo -e "${GREEN}[+] Installing pip3...${NC}"
            sudo apt install -y python3-pip
        fi

    elif [[ "$os" == "macos" ]]; then
        tools+=("bind")
        echo -e "${GREEN}[+] Detected macOS. Installing dependencies...${NC}"
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}[!] Homebrew is not installed. Please install Homebrew first: https://brew.sh/${NC}"
            exit 1
        fi
        for tool in "${tools[@]}"; do
            if ! brew list --formula "$tool" &> /dev/null; then
                echo -e "${GREEN}[+] Installing $tool...${NC}"
                brew install "$tool"
            else
                echo -e "${GREEN}[+] $tool is already installed.${NC}"
            fi
        done
        if ! command -v pip3 &> /dev/null; then
            echo -e "${GREEN}[+] Installing pip3...${NC}"
            brew install python3
        fi
    else
        echo -e "${RED}[!] Unsupported OS. Only Linux and macOS are supported.${NC}"
        exit 1
    fi
}

# Install Sublist3r
install_sublist3r() {
    if ! pip3 show sublist3r &> /dev/null; then
        echo -e "${GREEN}[+] Installing Sublist3r...${NC}"
        pip3 install sublist3r
    else
        echo -e "${GREEN}[+] Sublist3r is already installed.${NC}"
    fi
}

# Enumerate subdomains
enumerate_subdomains() {
    local domain="$1"
    echo -e "${GREEN}[+] Enumerating subdomains for: $domain${NC}"
    python3 -m sublist3r -d "$domain" -o subdomains.txt
    echo -e "${GREEN}[+] Subdomains saved to subdomains.txt${NC}"
}

# Resolve DNS
resolve_dns() {
    echo -e "${GREEN}[+] Resolving subdomains...${NC}"
    while read -r subdomain; do
        dig +short "$subdomain" >> resolved.txt
    done < subdomains.txt
    echo -e "${GREEN}[+] Resolved IPs saved to resolved.txt${NC}"
}

# Scan ports
scan_ports() {
    echo -e "${GREEN}[+] Scanning ports for resolved IPs...${NC}"
    while read -r ip; do
        nmap -Pn "$ip" >> nmap_results.txt
    done < resolved.txt
    echo -e "${GREEN}[+] Nmap results saved to nmap_results.txt${NC}"
}

# Fetch WHOIS information
fetch_whois() {
    local domain="$1"
    echo -e "${GREEN}[+] Fetching WHOIS information for: $domain${NC}"
    whois "$domain" > whois_info.txt
    echo -e "${GREEN}[+] WHOIS info saved to whois_info.txt${NC}"
}

# Clean up and prepare output files
prepare_output_files() {
    local files=("subdomains.txt" "resolved.txt" "nmap_results.txt" "whois_info.txt")
    for file in "${files[@]}"; do
        > "$file"
    done
}

# Main function
main() {
    echo -e "${GREEN}Enter the domain name (without https or http):${NC}"
    read -r domain
    if [[ -z "$domain" ]]; then
        echo -e "${RED}[!] Domain name cannot be empty.${NC}"
        exit 1
    fi

    prepare_output_files

    local os
    os=$(detect_os)
    if [[ "$os" == "unsupported" ]]; then
        echo -e "${RED}[!] Unsupported OS.${NC}"
        exit 1
    fi

    install_dependencies "$os"
    install_sublist3r
    enumerate_subdomains "$domain"
    resolve_dns
    scan_ports
    fetch_whois "$domain"
    echo -e "${GREEN}[+] Recon complete. Check the output files.${NC}"
}

# Run the script
main "$@"
