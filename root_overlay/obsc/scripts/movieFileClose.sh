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
else
  echo "No GPG key file found at '$KEY_FILE'. Assuming key was previously imported."
fi

# Get recipient from the keyring (assumes the key has a usable UID)
RECIPIENT=$(gpg --list-keys --with-colons | awk -F: '/^uid:/ { print $10; exit }')

if [ -z "$RECIPIENT" ]; then
  echo "No valid GPG recipient found. Skipping encryption."
  exit 0
fi

# Encrypt the file
echo "Encrypting $FILE_NAME..."
gpg --output "$FILE_NAME.gpg" --encrypt --recipient "$RECIPIENT" "$FILE_NAME"

# Verify encryption succeeded before deleting
if [ $? -eq 0 ]; then
  echo "Encryption successful. Deleting original file..."
  rm -f "$FILE_NAME"
else
  echo "Error during encryption. Original file not deleted."
fi