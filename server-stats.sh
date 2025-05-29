#!/bin/bash
################################################################################
# Script Name   : Server Stats
# Author        : Paul Sørensen
# Website       : https://paulsorensen.io
# GitHub        : https://github.com/paulsorensen
# Version       : 1.3
# Last Modified : 2025/05/29 04:21:11
#
# Description:
# Provides a snapshot of key system information.
#
# Usage: Refer to README.md for details on how to use this script.
#
# If you found this script useful, a small tip is appreciated ❤️
# https://buymeacoffee.com/paulsorensen
################################################################################

# Set locale to POSIX 'C' for consistent decimal formatting
export LC_NUMERIC=C

RED='\033[38;2;255;0;127m'
BLUE='\033[38;5;81m'
YELLOW='\033[38;2;223;245;13m'
NC='\033[0m'
echo -e "${BLUE}Server Stats by paulsorensen.io${NC}\n"

# Check if server-stats.conf exists
if [ ! -f "server-stats.conf" ]; then
  echo -e "${RED}Error: server-stats.conf file not found. Make sure to edit and rename server-stats.conf.example before you run this script${NC}"
  exit 1
fi

# Include source
source "$(dirname "${BASH_SOURCE[0]}")/server-stats.conf"

################################################################################
#  1. Time
################################################################################

if [ "${TIME}" = "on" ]; then
# System Time & Timezone
system_time=$(date +"%H:%M:%S")
timezone_name=$(timedatectl show --value --property=Timezone)
timezone_offset=$(date +"%z" | sed 's/\(.\)..$/\1/')
echo -e "${YELLOW}System Time:${NC} ${system_time} (${timezone_name} GMT${timezone_offset})"

# Uptime (Days, Hours, Minutes)
uptime_info=$(uptime -p | sed 's/up //')
echo -e "${YELLOW}Uptime:${NC} ${uptime_info}\n"
fi

################################################################################
#  2. Software Versions
################################################################################

if [ "${SOFTWARE_VERSIONS}" = "on" ]; then
# OS
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
kernel=$(uname -r)
echo -e "${YELLOW}OS:${NC} ${OS} (${kernel})"

# Nginx
if command -v nginx >/dev/null; then
    nginx_version=$(nginx -v 2>&1 | sed 's/.*nginx\///')
    echo -e "${YELLOW}Nginx Version:${NC} ${nginx_version}"
fi

# Apache
if command -v apache2 >/dev/null; then
    apache_version=$(apache2 -v | grep "Server Version" | awk '{print $3}' | cut -d'/' -f2)
    echo -e "${YELLOW}Apache Version:${NC} ${apache_version}"
elif command -v httpd >/dev/null; then
    apache_version=$(httpd -v | grep "Server Version" | awk '{print $3}' | cut -d'/' -f2)
    echo -e "${YELLOW}Apache Version:${NC} ${apache_version}"
fi

# PHP
if command -v php >/dev/null; then
    php_version=$(php -v | head -n 1 | awk '{print $2}')
    echo -e "${YELLOW}PHP Version:${NC} ${php_version}"
fi

# NodeJs
if command -v node >/dev/null; then
    node_version=$(node -v)
    echo -e "${YELLOW}NodeJs Version:${NC} ${node_version}"
fi

# MariaDB / MySQL
if command -v mariadb >/dev/null 2>&1; then
    db_version=$(mariadb --version | awk '{print $5}' | tr -d ',')
    db_type="MariaDB"
elif command -v mysql >/dev/null 2>&1; then
    version_output=$(mysql --version)
    db_version=$(echo "$version_output" | awk '{print $5}' | tr -d ',')
    [[ $version_output == *MariaDB* ]] && db_type="MariaDB" || db_type="MySQL"
fi
[[ -n "$db_version" ]] && echo -e "${YELLOW}${db_type} Version:${NC} ${db_version}"

# MSSQL
if command -v sqlcmd >/dev/null; then
    mssql_version=$(sqlcmd -? 2>&1 | grep -m1 -i "Version" | awk '{print $NF}')
    echo -e "${YELLOW}MSSQL Version:${NC} ${mssql_version}"
fi

# Apache Cassandra
if command -v cassandra >/dev/null; then
    cassandra_version=$(cassandra -v)
    echo -e "${YELLOW}Apache Cassandra Version:${NC} ${cassandra_version}"
fi

# Apache Solr
if command -v solr >/dev/null; then
    solr_version=$(solr -version 2>&1 | head -n1)
    echo -e "${YELLOW}Apache Solr Version:${NC} ${solr_version}"
fi

# MongoDB
if command -v mongod >/dev/null 2>&1; then
    mongo_version=$(mongod --version | awk '/db version/{print $3}')

    # Remove leading "v" if present
    [[ $mongo_version == v* ]] && mongo_version="${mongo_version:1}"
    echo -e "${YELLOW}MongoDB Version:${NC} ${mongo_version}"
fi

# Redis
if command -v redis-server >/dev/null; then
    redis_version=$(redis-server --version | awk '{print $3}' | cut -d'=' -f2)
    echo -e "${YELLOW}Redis Version:${NC} ${redis_version}"
fi

# RavenDB
if command -v ravendb >/dev/null; then
    ravendb_version=$(ravendb --version)
    echo -e "${YELLOW}RavenDB Version:${NC} ${ravendb_version}"
fi
echo ""
fi

################################################################################
#  3. System Updates Available
################################################################################

if [ "${SYSTEM_UPDATES}" = "on" ]; then
echo -e "${YELLOW}System Updates Available:${NC}"
total_updates=$(apt list --upgradable 2>/dev/null | grep -v '^Listing...' | wc -l)
critical_updates=$(apt list --upgradable 2>/dev/null | grep -v '^Listing...' | grep -i 'security' | wc -l)
echo -e "${BLUE}Total:${NC} ${total_updates}"

# If critical updates exist, make it bold red; otherwise, blue
if [ "$critical_updates" -gt 0 ]; then
    echo -e "\033[1m${RED}Critical:${NC} ${critical_updates}" # Bold Red
else
    echo -e "${BLUE}Critical:${NC} ${critical_updates}" # Normal Blue
fi
echo ""
fi

################################################################################
#  4. Logged-In Users
################################################################################

if [ "${LOGGED_IN_USERS}" = "on" ]; then
# Function to clean IP address
clean_ip() {
    local ip=$1
    ip=$(echo "$ip" | tr -d '()')
    [ -z "$ip" ] && ip="Local"
    echo "$ip"
}

# Function to format login time: YYYY-MM-DD HH:MM
format_login_time() {
    local date=$1
    local time=$2
    date -d "$date $time" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown"
}

# Function to process 'who' line and return formatted fields
process_who_line() {
    local line=$1
    # Split 'who' line into fields: User, Terminal, Date, Time, IP
    read -r user terminal date time ip <<< "$line"
    
    # Clean IP address
    ip=$(clean_ip "$ip")

    # Format login time
    login_time_formatted=$(format_login_time "$date" "$time")

    # Return fields in printing order: User, Terminal, Login Time, IP/Host
    echo "$user $terminal $login_time_formatted $ip"
}

echo -e "${YELLOW}Logged-In Users:${NC}"

# Get 'who' output to analyze column lengths
mapfile -t users < <(who 2>/dev/null)

# Set fixed spacing for consistent gaps between columns
space_between=5

# Define column headers
user_header="User"
terminal_header="Terminal"
login_time_header="Login Time"
ip_host_header="IP/Host"

# Get initial widths from header lengths
user_header_len=${#user_header}
terminal_header_len=${#terminal_header}
login_time_header_len=${#login_time_header}
ip_host_header_len=${#ip_host_header}

# Determine max widths dynamically, starting with header lengths
max_user_width=$user_header_len
max_terminal_width=$terminal_header_len
max_login_time_width=$login_time_header_len
max_ip_width=$ip_host_header_len

# Find longest content in each column (User, Terminal, Login Time, IP/Host) for dynamic sizing
for line in "${users[@]}"; do
    # Process the line and get formatted fields
    read -r user terminal login_time_formatted ip <<< "$(process_who_line "$line")"

    # Calculate lengths for printing order: User, Terminal, Login Time, IP/Host
    user_len=${#user}
    terminal_len=${#terminal}
    ip_len=${#ip}

    # Update max widths based on content length, matching print order
    max_user_width=$(( user_len > max_user_width ? user_len : max_user_width ))
    max_terminal_width=$(( terminal_len > max_terminal_width ? terminal_len : max_terminal_width ))
    max_login_time_width=$(( ${#login_time_formatted} > max_login_time_width ? ${#login_time_formatted} : max_login_time_width ))
    max_ip_width=$(( ip_len > max_ip_width ? ip_len : max_ip_width ))
done

# Ensure exactly 5 spaces between either column headers or column data,
# using dynamic column widths based on content length, with explicit 5-space
# gaps inserted where specified, though actual gaps may exceed 5 due to content.

# Print headers with 5-space gaps, allowing dynamic width but inserting 5 spaces
printf "${BLUE}%-${max_user_width}s" "$user_header"
printf "%${space_between}s" ""
printf "%-${max_terminal_width}s" "$terminal_header"
printf "%${space_between}s" ""
printf "%-${max_login_time_width}s" "$login_time_header"
printf "%${space_between}s" ""
printf "%s${NC}\n" "$ip_host_header"

# Print data rows with 5-space gaps, adjusting dynamically for content
for line in "${users[@]}"; do
    # Process the line and get formatted fields
    read -r user terminal login_time_formatted ip <<< "$(process_who_line "$line")"

    # Print row with 5-space gaps, allowing dynamic adjustment
    printf "${WHITE}%-${max_user_width}s" "$user"
    printf "%${space_between}s" ""
    printf "%-${max_terminal_width}s" "$terminal"
    printf "%${space_between}s" ""
    printf "%-${max_login_time_width}s" "$login_time_formatted"
    printf "%${space_between}s" ""
    printf "%s${NC}\n" "$ip"
done

echo ""
fi

################################################################################
#  5. Public Ports
################################################################################

if [ "${PUBLIC_PORTS}" = "on" ]; then
echo -e "${YELLOW}Public Ports:${NC}"
ss -tuln | awk '
    NR > 1 && $1 ~ /^(tcp|udp)$/ && $5 !~ /127\.|%lo|\[::1\]/ {
        split($5, a, ":")
        port = a[length(a)]
        proto = toupper($1)

        # Store port and protocol for sorting
        if (!(port in seen_ports)) {
            seen_ports[port] = proto
        } else {
            # If both TCP and UDP exist for the same port, store both
            seen_ports[port] = seen_ports[port] " " proto
        }
    }
    END {
        # Output the ports in a printable format for sorting
        for (port in seen_ports) {
            protypes = seen_ports[port]
            print port, protypes
        }
    }
' | sort -n -k1,1 | awk '
    {
        port = $1
        protypes = $2
        # Split TCP and UDP protocols for each port
        split(protypes, protocols, " ")

        # Print TCP ports first
        printed = 0
        for (j = 1; j <= length(protocols); j++) {
            proto = protocols[j]
            if (proto == "TCP" && printed == 0) {
                printf "%d (%s)", port, proto
                printed = 1
            } else if (proto == "UDP" && printed == 1) {
                printf "     %d (%s)", port, proto
            }
        }

        # Print UDP ports last
        if (printed == 0 && length(protocols) == 1 && protocols[1] == "UDP") {
            printf "%d (%s)", port, "UDP"
        }

        if (NR % 5 == 0) printf "\n"
        else printf "     "
    }
    END { if (NR % 5 != 0) print "" }
'
echo ""
fi

################################################################################
#  6. Network Traffic
################################################################################

if [ "${NETWORK_TRAFFIC}" = "on" ]; then
echo -e "${YELLOW}Network Traffic:${NC}"
printf "${BLUE}%-13s %-13s %-13s${NC}\n" "Interface" "In (MB/s)" "Out (MB/s)"
if [ -f /proc/net/dev ]; then
    # Get network stats for the primary interface (e.g., eth0 or ens3)
    primary_if=$(ip link show | grep -E '^[0-9]+: [a-z0-9]+' | grep -v 'lo:' | head -n 1 | awk '{print $2}' | tr -d ':')
    if [ -n "$primary_if" ]; then
        read -r _ rx_bytes _ _ _ _ _ _ _ tx_bytes _ < <(grep "$primary_if" /proc/net/dev)
        # Sleep briefly to measure rate, then re-read
        sleep 1
        read -r _ rx_bytes_new _ _ _ _ _ _ _ tx_bytes_new _ < <(grep "$primary_if" /proc/net/dev)
        # Calculate MB/s (bytes to MB / seconds)
        rx_mb=$(echo "scale=1; ($rx_bytes_new - $rx_bytes) / 1024 / 1024 / 1" | bc)
        tx_mb=$(echo "scale=1; ($tx_bytes_new - $tx_bytes) / 1024 / 1024 / 1" | bc)
        printf "${WHITE}%-13s %-13.1f %-13.1f${NC}\n" "$primary_if" "$rx_mb" "$tx_mb"
    else
        echo -e "${WHITE}No network interface found${NC}"
    fi
else
    echo -e "${WHITE}Network stats unavailable${NC}"
fi
echo ""
fi

################################################################################
#  7. CPU Info
################################################################################

if [ "${CPU_INFO}" = "on" ]; then
echo -e "${YELLOW}CPU Info:${NC}"
cores=$(nproc)

# Cores
echo -e "${BLUE}Cores:${NC} $cores"

# Total CPU Usage
total_cpu=$(grep -m1 "cpu MHz" /proc/cpuinfo | awk '{print $4}')
total_cpu_ghz=$(echo "scale=2; $total_cpu*$cores/1000" | bc)

# Get overall CPU idle percentage
overall_idle=$(mpstat 1 1 | awk '/Average/ && $NF ~ /[0-9.]+/ {print $NF}')

# Ensure overall_idle is numeric before calculating
if [[ ! -z "$overall_idle" && "$overall_idle" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    overall_usage=$(echo "scale=2; 100 - $overall_idle" | bc)
    used_cpu_ghz=$(echo "scale=2; $overall_usage * $total_cpu_ghz / 100" | bc)
else
    overall_usage="N/A"
    used_cpu_ghz="N/A"
fi

echo -e "${BLUE}Total CPU usage:${NC} ${used_cpu_ghz}/${total_cpu_ghz}GHz (${overall_usage}% usage)"
echo ""

# Per Core Usage
cores_per_row=4  # Number of cores per row
core_count=0
echo -e "${BLUE}Per Core Usage:${NC}"

# Define fixed width for core labels and dynamic width for percentages
core_label_width=8  # "[CoreX]"
min_percent_width=5 # Minimum width for percentages (to fit "0.0%")
column_spacing=5    # Fixed spacing between each column

mpstat -P ALL 1 1 | awk -v cores_per_row="$cores_per_row" -v core_w="$core_label_width" -v min_w="$min_percent_width" -v spacing="$column_spacing" '
/Average/ && $2 ~ /^[0-9]+$/ {
    usage = sprintf("%.1f%%", $3+$4);  # Format percentage
    width = (length(usage) > min_w) ? length(usage) : min_w;  # Adjust width dynamically
    printf "%-*s %-*s", core_w, "[Core" $2+1 "]", width, usage;

    core_count++;

    # Print spacing between columns
    if (core_count % cores_per_row != 0)
        printf "%" spacing "s", "";

    # Newline after every N cores
    if (core_count % cores_per_row == 0)
        printf "\n";
}
END { if (core_count % cores_per_row != 0) print "" }'
echo ""
fi

################################################################################
#  8. Memory Usage
################################################################################

if [ "${MEMORY_USAGE}" = "on" ]; then
echo -e "${YELLOW}Memory Usage:${NC}"
total_mem=$(free -m | awk '/Mem:/{printf "%.1f", $2/1024}')
used_mem=$(free -m | awk '/Mem:/{printf "%.1f", $3/1024}')
mem_pct=$(free | awk '/Mem:/{printf "%.1f", ($3/$2)*100}')
echo -e "${NC}${used_mem}/${total_mem}GB (${mem_pct}% used)${NC}\n"
fi

################################################################################
#  9. Disk Space
################################################################################

if [ "${DISK_SPACE}" = "on" ]; then
echo -e "${YELLOW}Disk Space:${NC}"
df -BG / | awk 'NR==2 {used=$3+0; total=$2+0; print used "/" total "GB (" $5 " used)"}'
echo ""
fi

################################################################################
#  10. Top 10 Memory Consuming Processes
################################################################################

if [ "${TOP_10_MEMORY}" = "on" ]; then
echo -e "${YELLOW}Top 10 Memory Consuming Processes:${NC}"

# Use awk to process ps output in a single pass, calculating max widths and printing formatted output
ps -eo rss,pid,user,comm --sort=-rss 2>/dev/null | head -n 11 | tail -n 10 | awk -v BLUE="$BLUE" -v WHITE="$WHITE" -v NC="$NC" '
    BEGIN {
        max_mb = 2; max_pid = 3; max_user = 4;  # Initial max widths
    }
    {
        mb = int($1 / 1024);  # Convert KB to MB
        pid = $2; user = $3; proc = $4;

        # Calculate lengths for dynamic widths
        mb_len = length(mb); pid_len = length(pid); user_len = length(user);

        # Update max widths if necessary
        if (mb_len > max_mb) max_mb = mb_len;
        if (pid_len > max_pid) max_pid = pid_len;
        if (user_len > max_user) max_user = user_len;

        # Store data for final print
        data[NR] = sprintf("%d %d %s %s", mb, pid, user, proc);
    }
    END {
        # Add padding (5 spaces) for each column
        mb_width = max_mb + 5;
        pid_width = max_pid + 5;
        user_width = max_user + 5;

        # Print header with dynamic widths
        printf "%s%-*s%-*s%-*s%s%s\n", BLUE, mb_width, "MB", pid_width, "PID", user_width, "USER", "PROCESS", NC;

        # Print data rows with dynamic widths
        for (i = 1; i <= NR; i++) {
            split(data[i], fields, " ");
            printf "%s%-*d%-*d%-*s%s\n", WHITE, mb_width, fields[1], pid_width, fields[2], user_width, fields[3], fields[4];
        }
    }
'
echo ""
fi

################################################################################
#  11. Top 10 CPU Consuming Processes
################################################################################

if [ "${TOP_10_CPU}" = "on" ]; then
echo -e "${YELLOW}Top 10 CPU Consuming Processes:${NC}"

# Use awk to process ps output in a single pass, calculating max widths and printing formatted output
ps -eo pcpu,pid,user,comm --sort=-pcpu 2>/dev/null | head -n 11 | tail -n 10 | awk -v BLUE="$BLUE" -v WHITE="$NC" '
    BEGIN {
        max_cpu = 4; max_pid = 3; max_user = 4;  # Initial max widths
    }
    {
        cpu = $1; pid = $2; user = $3; proc = $4;

        # Calculate lengths for dynamic widths
        cpu_len = length(sprintf("%.1f", cpu)); pid_len = length(pid); user_len = length(user);

        # Update max widths if necessary
        if (cpu_len > max_cpu) max_cpu = cpu_len;
        if (pid_len > max_pid) max_pid = pid_len;
        if (user_len > max_user) max_user = user_len;

        # Store data for final print
        data[NR] = sprintf("%.1f %d %s %s", cpu, pid, user, proc);
    }
    END {
        # Add padding (5 spaces) for each column
        cpu_width = max_cpu + 5;
        pid_width = max_pid + 5;
        user_width = max_user + 5;

        # Print header with dynamic widths
        printf "%s%-*s%-*s%-*s%s\n", BLUE, cpu_width, "%CPU", pid_width, "PID", user_width, "USER", "PROCESS";

        # Print data rows with dynamic widths
        for (i = 1; i <= NR; i++) {
            split(data[i], fields, " ");
            printf "%s%-*s%-*d%-*s%s\n", WHITE, cpu_width, fields[1], pid_width, fields[2], user_width, fields[3], fields[4];
        }
    }
'
echo ""
fi