#!/bin/bash

mkdir -p "$HOME/Documents/Productivity Helper"
cp runner.sh "Productivity Helper/Stats.html" "$HOME/Documents/Productivity Helper/"
cd "$HOME/Documents/Productivity Helper"
python -m http.server 8008
