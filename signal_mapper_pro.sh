#!/data/data/com.termux/files/usr/bin/bash

# Cellular Signal Mapper Pro
# Advanced signal strength mapping tool with animations
# Author: Termux-Elite
# Version: 2.0.0

# Configuration
VERSION="2.0.0"
LOG_FILE="signal_map_$(date +%Y%m%d_%H%M%S).csv"
MAX_SAMPLES=1000
SCAN_INTERVAL=3
ANIMATION_FRAMES=20
ANIMATION_SPEED=0.1

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Signal thresholds (dBm)
EXCELLENT=-80
GOOD=-90
FAIR=-100
POOR=-110

# Animation frames
ANIMATION[0]="[▓▓▓▓▓▓▓▓▓▓]"
ANIMATION[1]="[█▓▓▓▓▓▓▓▓▓]"
ANIMATION[2]="[██▓▓▓▓▓▓▓▓]"
ANIMATION[3]="[███▓▓▓▓▓▓▓]"
ANIMATION[4]="[████▓▓▓▓▓▓]"
ANIMATION[5]="[█████▓▓▓▓▓]"
ANIMATION[6]="[██████▓▓▓▓]"
ANIMATION[7]="[███████▓▓▓]"
ANIMATION[8]="[████████▓▓]"
ANIMATION[9]="[█████████▓]"
ANIMATION[10]="[██████████]"

# Check dependencies
check_dependencies() {
    local deps=("termux-api" "jq")
    for dep in "${deps[@]}"; do
        if ! pkg list-installed | grep -q "$dep"; then
            echo -e "${RED}Error: $dep not installed!${NC}"
            echo -e "Installing dependencies..."
            pkg install -y termux-api jq > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to install dependencies!${NC}"
                exit 1
            fi
        fi
    done
}

# Show cool banner
show_banner() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${CYAN}      CELLULAR SIGNAL MAPPER PRO v$VERSION     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${YELLOW}           Advanced Signal Analytics          ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}▶ Log: ${GREEN}$LOG_FILE${NC}"
    echo -e "${BLUE}▶ Max Samples: ${GREEN}$MAX_SAMPLES${NC}"
    echo -e "${BLUE}▶ Interval: ${GREEN}${SCAN_INTERVAL}s${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════${NC}"
}

# Animated progress bar
show_animation() {
    local frame=$((($1 % ${#ANIMATION[@]})))
    echo -ne "\r${ANIMATION[$frame]} Scanning... ${BLUE}($2/$3)${NC}"
    sleep $ANIMATION_SPEED
}

# Get precise signal info
get_signal_info() {
    local cell_info=$(timeout 8 termux-telephony-cellinfo)
    if [ $? -ne 0 ] || [ -z "$cell_info" ]; then
        echo "0,NO_DATA,0,UNKNOWN"
        return 1
    fi

    # Use jq to parse JSON properly
    local strength=$(echo "$cell_info" | jq -r '.[0].dbm // 0' 2>/dev/null)
    local type=$(echo "$cell_info" | jq -r '.[0].type // "UNKNOWN"' 2>/dev/null)
    local cid=$(echo "$cell_info" | jq -r '.[0].cid // 0' 2>/dev/null)
    local lac=$(echo "$cell_info" | jq -r '.[0].lac // 0' 2>/dev/null)

    echo "${strength:-0},${type:-UNKNOWN},${cid:-0},${lac:-0}"
}

# Get location with fallback
get_location() {
    local location_json=$(timeout 10 termux-location -p gps 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$location_json" ]; then
        local lat=$(echo "$location_json" | jq -r '.latitude // 0' 2>/dev/null)
        local lon=$(echo "$location_json" | jq -r '.longitude // 0' 2>/dev/null)
        local acc=$(echo "$location_json" | jq -r '.accuracy // 0' 2>/dev/null)
        echo "${lat:-0},${lon:-0},${acc:-0}"
        return 0
    fi

    # Network fallback
    location_json=$(timeout 10 termux-location -p network 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$location_json" ]; then
        local lat=$(echo "$location_json" | jq -r '.latitude // 0' 2>/dev/null)
        local lon=$(echo "$location_json" | jq -r '.longitude // 0' 2>/dev/null)
        local acc=$(echo "$location_json" | jq -r '.accuracy // 0' 2>/dev/null)
        echo "${lat:-0},${lon:-0},${acc:-0}"
        return 0
    fi

    echo "0,0,0"
}

# Evaluate signal quality with emoji
evaluate_signal() {
    local strength=$1
    case true in
        $(($strength >= $EXCELLENT))) echo -e "💚 EXCELLENT" ;;
        $(($strength >= $GOOD))) echo -e "💙 GOOD" ;;
        $(($strength >= $FAIR))) echo -e "💛 FAIR" ;;
        $(($strength >= $POOR))) echo -e "❤️ POOR" ;;
        *) echo -e "💔 NO SIGNAL" ;;
    esac
}

# Initialize log file
init_log() {
    echo "timestamp,latitude,longitude,accuracy,strength_dbm,network_type,cell_id,lac,quality" > "$LOG_FILE"
}

# Show real-time stats dashboard
show_dashboard() {
    local strength=$1
    local quality=$2
    local count=$3
    local total=$4
    
    echo -e "\n${WHITE}┌────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}            LIVE SIGNAL DASHBOARD${WHITE}            │${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${BLUE} Strength:${NC} ${strength} dBm $(printf "%*s" 15 "") ${WHITE}│${NC}"
    echo -e "${WHITE}│${BLUE} Quality: ${NC} $quality $(printf "%*s" 18 "") ${WHITE}│${NC}"
    echo -e "${WHITE}│${BLUE} Samples: ${NC} $count/$total $(printf "%*s" 20 "") ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────┘${NC}"
}

# Generate comprehensive report
generate_report() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${CYAN}           SCAN COMPLETE REPORT${PURPLE}            ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$LOG_FILE" ] || [ $(wc -l < "$LOG_FILE") -le 1 ]; then
        echo -e "${RED}No data collected!${NC}"
        return 1
    fi

    # Generate statistics
    local total=$((count-1))
    local avg_strength=$(tail -n +2 "$LOG_FILE" | cut -d, -f5 | awk '{sum+=$1} END {printf "%.1f", sum/NR}')
    local min_strength=$(tail -n +2 "$LOG_FILE" | cut -d, -f5 | sort -n | head -1)
    local max_strength=$(tail -n +2 "$LOG_FILE" | cut -d, -f5 | sort -n | tail -1)
    
    echo -e "${BLUE}📊 Statistics:${NC}"
    echo -e "${WHITE}├─ Samples: ${GREEN}$total${NC}"
    echo -e "${WHITE}├─ Avg Strength: ${GREEN}$avg_strength dBm${NC}"
    echo -e "${WHITE}├─ Min Strength: ${RED}$min_strength dBm${NC}"
    echo -e "${WHITE}└─ Max Strength: ${GREEN}$max_strength dBm${NC}"
    
    echo -e "\n${BLUE}📍 Data saved to: ${GREEN}$LOG_FILE${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════${NC}"
}

# Main execution flow
main() {
    check_dependencies
    init_log
    
    echo -e "${GREEN}🚀 Starting Cellular Signal Mapper Pro...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop scanning${NC}\n"
    sleep 2

    local count=1
    while [ $count -le $MAX_SAMPLES ]; do
        show_banner
        
        # Get data
        show_animation $count $count $MAX_SAMPLES
        local location=$(get_location)
        local signal_info=$(get_signal_info)
        
        # Parse data
        local lat=$(echo $location | cut -d, -f1)
        local lon=$(echo $location | cut -d, -f2)
        local acc=$(echo $location | cut -d, -f3)
        local strength=$(echo $signal_info | cut -d, -f1)
        local ntype=$(echo $signal_info | cut -d, -f2)
        local cell_id=$(echo $signal_info | cut -d, -f3)
        local lac=$(echo $signal_info | cut -d, -f4)
        local quality=$(evaluate_signal $strength)
        
        # Log and display
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$timestamp,$lat,$lon,$acc,$strength,$ntype,$cell_id,$lac,$quality" >> "$LOG_FILE"
        
        show_dashboard "$strength" "$quality" "$count" "$MAX_SAMPLES"
        
        count=$((count + 1))
        sleep $SCAN_INTERVAL
    done
    
    generate_report
}

# Handle interrupts gracefully
trap 'echo -e "\n${RED}🛑 Scan interrupted! Generating final report...${NC}"; generate_report; exit 0' INT

# Start the application
main "$@"
