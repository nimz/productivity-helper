#!/bin/bash

cd "$(dirname "$(realpath $0)")" # cd into base Productivity Helper source directory
PORT=$(cat port.txt)
mkdir -p "$HOME/Documents/Productivity Helper"
cp Productivity\ Helper/Stats*.html "$HOME/Documents/Productivity Helper/"
cd "$HOME/Documents/Productivity Helper"
if ! lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; then
  python -m http.server $PORT
fi
