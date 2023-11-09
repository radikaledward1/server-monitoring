#!/bin/bash

# Server Health Collector
# Description: Collects information about Memory Available, disk_info Space and if services as Apache and MySql are running.
# Version: 1.0.0
# Author: Oscar Gonzalez Gamboa
# Date: 2023-10-31
# License: GPL 2+

# Server Information
HOST=$(uname -n)
IPV4=$(hostname -I | awk '{print $1}')

# Disk Space
disk_info=$(df -h / | awk 'NR==2{print $2, $3, $4, $5}')

read dtotal dused dfree dpercent <<< $disk_info

#TOTALD=$(echo "$disk_info" | awk '{ print $1}')
#USED=$(echo "$disk_info" | awk '{ print $2}')
#FREED=$(echo "$disk_info" | awk '{ print $3}')
#USEDP=$(echo "$disk_info" | awk '{ print $4}' | cut -d'%' -f1 )

#echo $TOTALD
#echo $USED
#echo $FREED
#echo $USEDP

#echo "Disk Status"
#echo "Total: $dtotal, Used: $dused, Available: $dfree, Use: $dpercent"

# Memory
mem_info=$(free -g | awk 'NR==2{print $2, $3, $4, $6, $7}')

read mtotal mused mfree mcache mavailable <<< $mem_info

#echo "Memory Status"
#echo "Total: $mtotal MB, Used: $mused MB, Available: $mfree MB, Use: $mpercent%"

# General variables used to get memory information from Apcache and MySQL services
systemctl_status_output=''
memory_line=''
memory_used=''

# Apache
APACHE_STATUS=''
APACHE_MEMORY=''

if ps aux | grep -q '[a]pache2'; then
    APACHE_STATUS="Running"
else
    APACHE_STATUS="Down"
fi

# Memory Consumed by Apache from RSS
# if ps aux | grep -q '[a]pache2'; then
#     # get Apache PID
#     apache_pid=$(pgrep apache2 | head -n 1)
    
#     # Get RSS Memory (Resident Set Size) from Apache
#     apache_memory_kb=$(pmap -x "$apache_pid" | grep "total" | awk '{print $4}')

#     #Convert KB to GB
#     apache_memory_gb=$(awk "BEGIN {printf \"%.2f\", $apache_memory_kb / 1024 / 1024}")

#     APACHE_MEMORY=$apache_memory_gb
# else
#     APACHE_MEMORY="Not Available"
# fi

# Get Memory Consumed by Apache from "systemctl status apache2"
systemctl_status_output=$(systemctl status apache2)

if [[ $systemctl_status_output =~ "Memory:" ]]; then
    memory_line=$(echo "$systemctl_status_output" | grep "Memory:")
    memory_used=$(echo "$memory_line" | awk '{print $2}')
    APACHE_MEMORY=$memory_used
else
    APACHE_MEMORY="Not Available"
fi

# MySQL

MYSQL_STATUS=''
MYSQL_MEMORY=''

if ps aux | grep -q '[m]ysqld'; then
    MYSQL_STATUS="Running"
else
    MYSQL_STATUS="Down"
    #exit 1  # Exit with error
fi

# Memory Consumed by MySQL from RSS
# if ps aux | grep -q '[m]ysqld'; then
#     # get MySql PID
#     mysql_pid=$(pgrep mysqld)
    
#     # Get RSS Memory (Resident Set Size) from MySql
#     mysql_memory_kb=$(pmap -x "$mysql_pid" | grep "total" | awk '{print $4}')

#     # Convert KB to GB
#     mysql_memory_gb=$(awk "BEGIN {printf \"%.2f\", $mysql_memory_kb / 1024 / 1024}")

#     MYSQL_MEMORY=$mysql_memory_gb
# else
#     MYSQL_MEMORY="Not Available"
# fi

# Get Memory Consumed by MySQL from "systemctl status mysql.service"
systemctl_status_output=$(systemctl status mysql.service)

if [[ $systemctl_status_output =~ "Memory:" ]]; then
    memory_line=$(echo "$systemctl_status_output" | grep "Memory:")
    memory_used=$(echo "$memory_line" | awk '{print $2}')
    MYSQL_MEMORY=$memory_used
else
    MYSQL_MEMORY="Not Available"
fi

status="\nHost: $HOST\n
IP: $IPV4\n
Disk: Total: $dtotal, Used: $dused, Free: $dfree, Use: $dpercent\n
Memory: Total: $mtotal GB, Used: $mused GB, Free: $mfree GB, Cache: $mcache GB, Available: $mavailable GB\n
Apache: $APACHE_STATUS, Memory: $APACHE_MEMORY\n
MySQL: $MYSQL_STATUS, Memory: $MYSQL_MEMORY\n"

echo -e $status