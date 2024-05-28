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
  [SPACER]="_"
)

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
    mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '$nim'@'localhost';"

    # Print the privileges
    echo "Privileges revoked for $nim"

    # Drop the user
    mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "DROP USER IF EXISTS '$nim'@'localhost';"

    # Print the user name
    echo "User $nim dropped"
  done < $file
done

# Print the completion message
echo "All users and databases dropped"
