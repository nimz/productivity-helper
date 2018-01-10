#!/bin/bash

if [ "$#" -eq 0 ]; then PORT=8008; else PORT=$1; fi

if lsof -Pi :$PORT -sTCP:LISTEN -t > /dev/null; then
  kill -9 $(lsof -Pi :$PORT -sTCP:LISTEN -t)
fi
