#!/bin/bash

declare IP="192.168.9.202"
declare meter0="http://"$IP"/emeter/0"
declare meter1="http://"$IP"/emeter/1"

# customize the channel for meter active power
# curl -s http://192.168.9.202/emeter/0 | jq -r ".power"
command="curl -s "$meter0" | jq -r .'power'"

value=$(eval $command)
echo $value
