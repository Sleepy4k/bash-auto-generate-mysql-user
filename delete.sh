#!/bin/bash

# Init array to store configuration
typeset -A config

# Set default values, please do not change this
# except you know what you are doing
# This is the default configuration
config=(
  [DB_USERNAME]="root"
  [DB_PASSWORD]=""
  [DB_NAME]="test"
  [USER_HOST]="localhost"
  [SPACER]="_"
)

# Check if there is any file exists with the pattern
if [ ! -f data/nim_kelas_*.txt ]; then
  echo "No file found with the pattern data/nim_kelas_*.txt"
  exit 1
fi

# Read the configuration file and set the values from generated.conf
# If the configuration file is not found, use the default values
# If the configuration file is found, override the default values
while IFS='=' read -r key value;
do
  # If the line is empty, or if key and value is empty, then skip
  if [ -z "$key" ] || [ -z "$value" ]; then
    continue
  fi

  # Unwrap the value
  value=$(echo $value | sed 's/^"\(.*\)"$/\1/')

  # Set the value to the key
  config[$key]=$value
done < generate.conf

# Read content from file on data folder
for file in data/nim_kelas_*.txt; do
  # Loop through the file
  while IFS= read -r line; do
    nim=$(echo $line | cut -d ' ' -f 1)

    # Drop the database
    mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "DROP DATABASE IF EXISTS $nim${config[SPACER]}${config[DB_NAME]};"

    # Print the database name
    echo "Database $nim${config[SPACER]}${config[DB_NAME]} dropped"

    # Drop the privileges
    mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '$nim'@'${config[USER_HOST]}';"

    # Print the privileges
    echo "Privileges revoked for $nim on host ${config[USER_HOST]}"

    # Drop the user
    mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "DROP USER IF EXISTS '$nim'@'${config[USER_HOST]}';"

    # Print the user name
    echo "User $nim dropped for host ${config[USER_HOST]}"
  done < $file
done

# Print the completion message
echo "All users and databases dropped"
