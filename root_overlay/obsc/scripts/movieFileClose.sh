#!/bin/bash

FILE_NAME="$1"
KEY_FILE="/obsc/config/server_key.asc"

# Check if the file exists
if [ ! -f "$FILE_NAME" ]; then
  echo "Error: File '$FILE_NAME' not found."
  exit 1
fi

# Import the key if the file exists
if [ -f "$KEY_FILE" ]; then
  echo "Importing GPG key from $KEY_FILE..."
  gpg --import "$KEY_FILE"

  echo "Encrypting $FILE_NAME..."
  gpg --batch --yes --trust-model always \
      --output "$FILE_NAME.gpg" \
      --encrypt --recipient Obscura_Key \
      "$FILE_NAME"

  if [ $? -eq 0 ]; then
    echo "Encryption successful. Deleting original file..."
    rm -f "$FILE_NAME"
    FILE_NAME=$FILE_NAME.gpg
  else
    echo "Error during encryption. Original file not deleted."
  fi
else
  echo "No GPG key file found at '$KEY_FILE'. Assuming key was previously imported."
fi

logger "Proceeding with $FILE_NAME upload....."