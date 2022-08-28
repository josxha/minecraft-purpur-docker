#!/bin/sh

result=$(netstat -tlpn | grep LISTEN | grep 25565)
size=${#result}
if [ $size -eq 0 ]; then
  echo "Server not listening for connections"
  exit 1
else
  echo "No problems found"
  exit 0
fi
