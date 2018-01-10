#!/bin/bash

# NOTE: This script is not currently called by the application. However, it can still be run manually.

if [ "$#" -eq 0 ]; then PORT=8008; else PORT=$1; fi

if lsof -Pi :$PORT -sTCP:LISTEN | grep ython > /dev/null; then # kill process using port iff it is a python server
  kill -9 $(lsof -Pi :$PORT -sTCP:LISTEN -t)
fi
