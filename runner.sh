#!/bin/bash

# Change REPO_PARENT to the directory in which the repository was cloned
# Copy this script to the '~/Documents/Productivity Helper' directory and run it in the background,
# in order to view visualizations
REPO_PARENT="$HOME/Documents/github_repos/Productivity Helper/"
cp "$REPO_PARENT/Productivity Helper/Stats.html" .
python -m http.server 8008
