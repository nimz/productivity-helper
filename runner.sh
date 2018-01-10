#!/bin/bash

if [ "$#" -eq 0 ]; then PORT=8008; else PORT=$1; fi

cd "$(dirname "$(realpath $0)")" # cd into base Productivity Helper source directory
mkdir -p "$HOME/Documents/Productivity Helper"
cp Productivity\ Helper/Stats*.html "$HOME/Documents/Productivity Helper/"
cd "$HOME/Documents/Productivity Helper"
if ! lsof -Pi :$PORT -sTCP:LISTEN -t > /dev/null; then
  python2 -m SimpleHTTPServer $PORT
fi
