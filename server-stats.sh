#!/bin/bash
################################################################################
#  Script Name : Server Stats
#  Author      : Paul Sørensen
#  Website     : https://paulsorensen.io
#  GitHub      : https://github.com/paulsorensen
#  Version     : 1.0
#  Last Update : 25.02.2025
#
#  Description:
#  Provides a snapshot of key system information.
#
#  If you found this script useful, a small tip is appreciated ❤️
#  https://buymeacoffee.com/paulsorensen
################################################################################

RED='\033[38;2;255;0;127m'
BLUE='\033[38;5;81m'
YELLOW='\033[38;2;223;245;13m'
NC='\033[0m'
echo -e "${BLUE}Server Stats by paulsorensen.io${NC}\n"

################################################################################
#  1. Time
################################################################################

# System Time & Timezone
system_time=$(date +"%H:%M:%S")
timezone_name=$(timedatectl | grep "Time zone" | awk '{print $3}')
timezone_offset=$(date +"%z" | sed 's/\(.\)..$/\1/')
echo -e "${YELLOW}System Time:${NC} ${system_time} (${timezone_name} GMT${timezone_offset})"

# Uptime (Days, Hours, Minutes)
uptime_info=$(uptime -p | sed 's/up //')
echo -e "${YELLOW}Uptime:${NC} ${uptime_info}\n"

################################################################################
#  2. Software Versions
################################################################################

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

################################################################################
#  3. System Updates Available
################################################################################

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

################################################################################
#  4. Logged-In Users
################################################################################

echo -e "${YELLOW}Logged-In Users:${NC}"
# Determine max width for User column
max_user_width=$(who | awk '{print length($1)}' | sort -nr | head -n1)
max_user_width=$((max_user_width > 4 ? max_user_width : 4))  # Minimum width

# Define column spacing
space_between=5
user_column_width=$((max_user_width + space_between))
login_time_width=16  # Fixed width for login time
terminal_width=10    # Enough for terminal names
ip_width=20          # Fixed width for IP/hostname

# Print headers
printf "${BLUE}%-*s%-*s%-*s%-*s${NC}\n" "$user_column_width" "User" "$((login_time_width + space_between))" "Login Time" "$terminal_width" "Terminal" "$ip_width" "IP/Host"

# Process 'who' output
who 2>/dev/null | while read -r user terminal date time ip; do
    # Remove parentheses from IP and handle missing IP
    ip=$(echo "$ip" | tr -d '()')  # Strip parentheses
    [ -z "$ip" ] && ip="Local"     # Set "Local" if IP is empty

    # Format login time (e.g., "2025-03-02 23:57" -> "2025-03-02 23:57")
    login_time_formatted=$(date -d "$date $time" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")

    # Print formatted row
    printf "${WHITE}%-*s%-*s%-*s%-*s${NC}\n" "$user_column_width" "$user" "$((login_time_width + space_between))" "$login_time_formatted" "$terminal_width" "$terminal" "$ip_width" "$ip"
done

echo ""

################################################################################
#  5. Public Ports
################################################################################

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

################################################################################
#  6. Network Traffic
################################################################################

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

################################################################################
#  7. CPU Info
################################################################################

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

################################################################################
#  8. Memory Usage
################################################################################

echo -e "${YELLOW}Memory Usage:${NC}"
total_mem=$(free -m | awk '/Mem:/{printf "%.1f", $2/1024}')
used_mem=$(free -m | awk '/Mem:/{printf "%.1f", $3/1024}')
mem_pct=$(free | awk '/Mem:/{printf "%.1f", ($3/$2)*100}')
echo -e "${NC}${used_mem}/${total_mem}GB (${mem_pct}% used)${NC}\n"

################################################################################
#  9. Disk Space
################################################################################

echo -e "${YELLOW}Disk Space:${NC}"
df -BG / | awk 'NR==2 {used=$3+0; total=$2+0; print used "/" total "GB (" $5 " used)"}'
echo ""

################################################################################
#  10. Top 10 Memory Consuming Processes
################################################################################

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

################################################################################
#  11. Top 10 CPU Consuming Processes
################################################################################

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