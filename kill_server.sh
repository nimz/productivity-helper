#!/bin/bash

cd "$(dirname "$(realpath $0)")"
PORT=$(cat port.txt)
if lsof -Pi :$PORT -sTCP:LISTEN -t; then
  kill -9 $(lsof -Pi :$PORT -sTCP:LISTEN -t)
fi
