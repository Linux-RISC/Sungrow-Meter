#!/bin/bash

declare IP="192.168.9.202"
declare meter0="http://"$IP"/emeter/0"
declare meter1="http://"$IP"/emeter/1"

# customize the channel for meter voltage
# curl -s http://192.168.9.202/emeter/0 | jq -r ".voltage"
command="curl -s "$meter0" | jq -r .'voltage'"

value=$(eval $command)
echo $value
