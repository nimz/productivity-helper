#!/bin/bash

if [ "$#" -eq 0 ]; then PORT=8008; else PORT=$1; fi

mkdir -p "$HOME/Documents/Productivity Helper/scripts"
cd "$HOME/Documents/Productivity Helper"
rm Stats.html # Remove the old file (once the UI is stable, this can be omitted)

pyversion=$(python -c 'import sys; print(sys.version_info[0])')
if [[ $pyversion -eq 3 ]]; then
  httpstr=http.server
elif [[ $pyversion -eq 2 ]]; then
  httpstr=SimpleHTTPServer
else
  exit 1
fi
if ! lsof -Pi :$PORT -sTCP:LISTEN -t > /dev/null; then
  nohup python -m $httpstr $PORT &> ~/lolcats.txt &
fi
