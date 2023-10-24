#!/bin/bash

# Domains Response Checker
# Description: Checks if the list of domain servers and their websites listed in the file domains.tx are responding.
# Version: 1.0.0
# Author: Oscar Gonzalez Gamboa
# Date: 2023-10-23
# License: GPL 2+

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

SUCCESSED=0
ISSUED=0

CALLS=5

STATUSES=()

readarray() {
  local __resultvar=$1
  declare -a __local_array
  let i=0
  while IFS=$'\n' read -r line_data; do
      __local_array[i]=${line_data}
      ((++i))
  done < $2
  if [[ "$__resultvar" ]]; then
    eval $__resultvar="'${__local_array[@]}'"
  else
    echo "${__local_array[@]}"
  fi
}

countdomains () {
  #Count how many domains are listed in the file domains.txt
  local DOMAINS=$(wc -l domains.txt | awk '{print $1}')
  echo "$DOMAINS"
}

pingtest () {
  ping -c "$CALLS" "$1" || return 1
}

servercheck () {
  local res=$1
  # 1 means false (no error), 2 means true (error)
   if ! pingtest $2; then
    echo "${YELLOW}WARNING${NC}: The server for $2 is not responding."
    eval $res=2
  else
    echo "${GREEN}SUCCESS${NC}: The server for $2 is responding."
    eval $res=1
  fi
}

websitecheck () {
  local res=$1
  # 1 means false (no error), 2 means true (error)
  # curl -s --head  --request GET "$1" | grep "200 OK" > /dev/null;
  if curl -s --head  --request GET "$2" > /dev/null; then 
    echo "${GREEN}SUCCESS${NC}: The website $2 is up running."
    eval $res=1   
  else
    echo "${YELLOW}WARNING${NC}: The website $2 is down."
    eval $res=2
  fi
}

reportmessages () {
  local scheck=$1
  local wcheck=$2
  local domain=$3

  local scmsg=""
  local swmsg=""
  local type=""

  if [[ $scheck -eq 1 && $wcheck -eq 1 ]]; then
    ((SUCCESSED++))
    type="SUCCESS"
  else
    ((ISSUED++))
    type="ISSUED"
  fi

  if [ $scheck -eq 1 ]; then
    scmsg="Responding"
  else
    scmsg="Not Responding"
  fi

  if [ $wcheck -eq 1 ]; then
    swmsg="Up"
  else
    swmsg="Down"
  fi

  stmsg="$type - Domain: $domain, Server: $scmsg, Website: $swmsg"
  STATUSES+=("$stmsg")
}

# Retrive the list of domains from the file domains.txt
readarray DOMAINS domains.txt

# Make the request calls for each domain listed in the file domains.txt and check the server and website availability
for DOMAIN in $DOMAINS
do
  echo "\n"

  servercheck SCHECK $DOMAIN
  websitecheck WCHECK $DOMAIN

  reportmessages $SCHECK $WCHECK $DOMAIN
done

#Creates the report file
if [ -f report.txt ]; then
  rm report.txt
fi

cat << EOF >> report.txt
DOMAINS CHECKER REPORT

=======================================================================
The followed is a report after checked the list of domains listed in
'domains.txt' file for server and website availability.
=======================================================================


EOF

numdomains=$(countdomains)
echo "Domains: $numdomains" >> report.txt
echo "Successed: $SUCCESSED" >> report.txt
echo "Issued: $ISSUED" >> report.txt
echo "\n" >> report.txt

for STATUS in "${STATUSES[@]}"
do
  echo "$STATUS" >> report.txt
done