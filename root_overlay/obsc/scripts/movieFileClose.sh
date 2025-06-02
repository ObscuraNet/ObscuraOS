#!/bin/bash

FILE_NAME="$1"
KEY_FILE="/obsc/config/server_key.asc"

# Check if the file exists
if [ ! -f "$FILE_NAME" ]; then
  echo "Error: File '$FILE_NAME' not found."
  exit 1
fi

logger "Proceeding with $FILE_NAME upload....."