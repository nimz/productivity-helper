#!/bin/bash

mkdir -p "$HOME/Documents/Productivity Helper/scripts"
cd "$HOME/Documents/Productivity Helper"

if [ "$#" -eq 0 ]; then PORT=8008; else PORT=$1; fi

pyversion=$(python -c 'import sys; print(sys.version_info[0])')
if [[ $pyversion -eq 3 ]]; then
  httpstr=http.server
elif [[ $pyversion -eq 2 ]]; then
  httpstr=SimpleHTTPServer
else
  exit 1
fi
if ! lsof -Pi :$PORT -sTCP:LISTEN -t > /dev/null; then
  nohup python -m $httpstr $PORT &> /dev/null & # redirecting output appears to be necessary for some reason
fi
