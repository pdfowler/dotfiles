#!/bin/bash
# Network diagnostics script for server connectivity troubleshooting
# Usage: network-diagnostics.sh [hostname|ip]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default server info
DEFAULT_HOSTNAME="dean"
DEFAULT_IP="192.168.13.105"
SCREEN_SHARING_PORT=5900
SSH_PORT=22

# Parse arguments
TARGET="${1:-$DEFAULT_HOSTNAME}"
TARGET_IP="${2:-$DEFAULT_IP}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Network Connectivity Diagnostics${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section header
print_section() {
    echo ""
    echo -e "${CYAN}─── $1 ───${NC}"
}

# Function to print test result
print_result() {
    local status=$1
    local message=$2
    if [ $status -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $message"
    else
        echo -e "  ${RED}✗${NC} $message"
    fi
}

# 1. Basic connectivity tests
print_section "Basic Connectivity"

# Ping test
if command_exists ping; then
    echo -e "${YELLOW}Testing ping to $TARGET_IP...${NC}"
    if ping -c 3 -W 2 "$TARGET_IP" >/dev/null 2>&1; then
        print_result 0 "Ping successful to $TARGET_IP"
        # Show ping stats
        ping -c 3 -W 2 "$TARGET_IP" 2>/dev/null | tail -2 | sed 's/^/    /'
    else
        print_result 1 "Ping failed to $TARGET_IP"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} ping command not available"
fi

# 2. DNS Resolution
print_section "DNS Resolution"

# Resolve hostname to IP
if command_exists host; then
    echo -e "${YELLOW}Resolving hostname: $TARGET${NC}"
    resolved_ip=$(host "$TARGET" 2>/dev/null | grep "has address" | awk '{print $4}' | head -1)
    if [ -n "$resolved_ip" ]; then
        print_result 0 "$TARGET resolves to $resolved_ip"
        if [ "$resolved_ip" != "$TARGET_IP" ]; then
            echo -e "  ${YELLOW}⚠${NC} Resolved IP ($resolved_ip) differs from expected ($TARGET_IP)"
        fi
    else
        print_result 1 "$TARGET does not resolve via DNS"
    fi
elif command_exists nslookup; then
    echo -e "${YELLOW}Resolving hostname: $TARGET${NC}"
    resolved_ip=$(nslookup "$TARGET" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
    if [ -n "$resolved_ip" ]; then
        print_result 0 "$TARGET resolves to $resolved_ip"
        if [ "$resolved_ip" != "$TARGET_IP" ]; then
            echo -e "  ${YELLOW}⚠${NC} Resolved IP ($resolved_ip) differs from expected ($TARGET_IP)"
        fi
    else
        print_result 1 "$TARGET does not resolve via DNS"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} DNS lookup tools not available"
fi

# Reverse DNS lookup
if command_exists host; then
    echo -e "${YELLOW}Reverse DNS lookup for $TARGET_IP...${NC}"
    reverse_name=$(host "$TARGET_IP" 2>/dev/null | grep "pointer" | awk '{print $5}' | head -1)
    if [ -n "$reverse_name" ]; then
        print_result 0 "$TARGET_IP reverse resolves to $reverse_name"
    else
        print_result 1 "$TARGET_IP does not reverse resolve"
    fi
fi

# 3. Port connectivity tests
print_section "Port Connectivity"

# Test Screen Sharing port (5900)
if command_exists nc; then
    echo -e "${YELLOW}Testing Screen Sharing port ($SCREEN_SHARING_PORT)...${NC}"
    if nc -z -w 2 "$TARGET_IP" "$SCREEN_SHARING_PORT" 2>/dev/null; then
        print_result 0 "Port $SCREEN_SHARING_PORT (Screen Sharing) is open"
    else
        print_result 1 "Port $SCREEN_SHARING_PORT (Screen Sharing) is closed or unreachable"
    fi
elif command_exists timeout; then
    if timeout 2 bash -c "echo > /dev/tcp/$TARGET_IP/$SCREEN_SHARING_PORT" 2>/dev/null; then
        print_result 0 "Port $SCREEN_SHARING_PORT (Screen Sharing) is open"
    else
        print_result 1 "Port $SCREEN_SHARING_PORT (Screen Sharing) is closed or unreachable"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Port testing tools not available"
fi

# Test SSH port (22)
if command_exists nc; then
    echo -e "${YELLOW}Testing SSH port ($SSH_PORT)...${NC}"
    if nc -z -w 2 "$TARGET_IP" "$SSH_PORT" 2>/dev/null; then
        print_result 0 "Port $SSH_PORT (SSH) is open"
    else
        print_result 1 "Port $SSH_PORT (SSH) is closed or unreachable"
    fi
fi

# 4. Network path diagnostics
print_section "Network Path"

# Traceroute
if command_exists traceroute; then
    echo -e "${YELLOW}Tracing route to $TARGET_IP...${NC}"
    echo -e "${BLUE}First 5 hops:${NC}"
    traceroute -m 5 "$TARGET_IP" 2>/dev/null | head -6 | sed 's/^/    /'
elif command_exists tracepath; then
    echo -e "${YELLOW}Tracing path to $TARGET_IP...${NC}"
    tracepath "$TARGET_IP" 2>/dev/null | head -10 | sed 's/^/    /'
else
    echo -e "  ${YELLOW}⚠${NC} Traceroute tools not available"
fi

# 5. ARP table check
print_section "Local Network"

# Check ARP table
if command_exists arp; then
    echo -e "${YELLOW}Checking ARP table for $TARGET_IP...${NC}"
    arp_entry=$(arp -n "$TARGET_IP" 2>/dev/null | grep -v "incomplete")
    if [ -n "$arp_entry" ]; then
        print_result 0 "ARP entry found"
        echo "$arp_entry" | sed 's/^/    /'
    else
        print_result 1 "No ARP entry found (may indicate connectivity issue)"
    fi
fi

# Check local network interface
if command_exists ifconfig; then
    echo -e "${YELLOW}Local network interfaces:${NC}"
    ifconfig | grep -E "^[a-z]|inet " | grep -B1 "inet " | sed 's/^/    /'
elif command_exists ip; then
    echo -e "${YELLOW}Local network interfaces:${NC}"
    ip addr show | grep -E "^[0-9]|inet " | sed 's/^/    /'
fi

# 6. Screen Sharing specific tests
print_section "Screen Sharing Diagnostics"

# Check if we can resolve via hostname
if [ "$TARGET" != "$TARGET_IP" ]; then
    echo -e "${YELLOW}Testing connectivity via hostname ($TARGET)...${NC}"
    if ping -c 1 -W 1 "$TARGET" >/dev/null 2>&1; then
        print_result 0 "Hostname resolves and is reachable"
    else
        print_result 1 "Hostname does not resolve or is unreachable"
        echo -e "  ${YELLOW}💡${NC} Try using IP address directly: $TARGET_IP"
    fi
fi

# Test VNC/Screen Sharing connection
if command_exists vncviewer || command_exists open; then
    echo -e "${YELLOW}Screen Sharing connection info:${NC}"
    echo -e "  Hostname: ${CYAN}$TARGET${NC}"
    echo -e "  IP: ${CYAN}$TARGET_IP${NC}"
    echo -e "  Port: ${CYAN}$SCREEN_SHARING_PORT${NC}"
    echo -e "  Connection string: ${CYAN}vnc://$TARGET_IP${NC}"
    echo -e "  Or via hostname: ${CYAN}vnc://$TARGET${NC}"
else
    echo -e "  ${YELLOW}⚠${NC} VNC client not detected"
fi

# 7. Certificate/DNS issues (related to UniFi changes)
print_section "Certificate & DNS (UniFi Related)"

echo -e "${YELLOW}Checking for potential certificate/DNS issues...${NC}"

# Check if hostname matches expected domain
if [[ "$TARGET" == *".pdfowler.net" ]]; then
    print_result 0 "Hostname uses pdfowler.net domain"
else
    echo -e "  ${YELLOW}⚠${NC} Hostname does not use pdfowler.net domain"
    echo -e "  ${YELLOW}💡${NC} Consider: $TARGET.pdfowler.net"
fi

# Check /etc/hosts for manual entries
if [ -f /etc/hosts ]; then
    echo -e "${YELLOW}Checking /etc/hosts for manual entries...${NC}"
    hosts_entry=$(grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\s+.*$TARGET" /etc/hosts 2>/dev/null)
    if [ -n "$hosts_entry" ]; then
        print_result 0 "Found /etc/hosts entry"
        echo "$hosts_entry" | sed 's/^/    /'
    else
        echo -e "  ${BLUE}ℹ${NC} No /etc/hosts entry found for $TARGET"
    fi
fi

# 8. Summary and recommendations
print_section "Summary & Recommendations"

echo -e "${YELLOW}Server Information:${NC}"
echo -e "  Hostname: ${CYAN}$TARGET${NC}"
echo -e "  IP Address: ${CYAN}$TARGET_IP${NC}"
echo -e "  Screen Sharing Port: ${CYAN}$SCREEN_SHARING_PORT${NC}"

echo ""
echo -e "${YELLOW}Troubleshooting Tips:${NC}"
echo -e "  1. If ping fails, check physical network connection"
echo -e "  2. If DNS resolution fails, check UniFi DNS settings"
echo -e "  3. If port $SCREEN_SHARING_PORT is closed, check firewall rules"
echo -e "  4. If hostname doesn't work, try connecting via IP: vnc://$TARGET_IP"
echo -e "  5. Certificate issues may require:"
echo -e "     - Clearing DNS cache: sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
echo -e "     - Checking UniFi controller for DNS/certificate configuration"
echo -e "  6. For intermittent issues, check:"
echo -e "     - Network switch port status"
echo -e "     - Mac sleep/wake settings"
echo -e "     - UniFi AP signal strength"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

