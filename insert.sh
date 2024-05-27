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
  [DB_PREFIX]="2311102"
  [DB_SUFFIX_START]="001"
  [DB_SUFFIX_END]="002"
  [SPACER]="_"
)

# Read the configuration file and set the values from generate.conf
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

# Loop each data from DB_SUFFIX_START to DB_SUFFIX_END
for i in $(seq -f "%03g" ${config[DB_SUFFIX_START]} ${config[DB_SUFFIX_END]})
do
  # if variable i length is less than domain end length then add 0 to the start of i
  # example if DB_SUFFIX_END is 10, then 1 will be 01, and if 1000 then 0001
  if [ ${#i} -lt ${#config[DB_SUFFIX_END]} ]; then
    i="0$i"
  fi

  # Create the user
  mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "CREATE USER IF NOT EXISTS '${config[DB_PREFIX]}$i'@'localhost' IDENTIFIED BY '${config[DB_PREFIX]}$i';"

  # Print the user name
  echo "User ${config[DB_PREFIX]}$i created"

  # Grant privileges
  mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "GRANT ALL PRIVILEGES ON ${config[DB_PREFIX]}$i${config[SPACER]}.* TO '${config[DB_PREFIX]}$i'@'localhost';"

  # Print the privileges
  echo "Privileges granted for ${config[DB_PREFIX]}$i${config[SPACER]}"

  # Create the database
  mysql -u "${config[DB_USERNAME]}" -p"${config[DB_PASSWORD]}" -e "CREATE DATABASE IF NOT EXISTS ${config[DB_PREFIX]}$i${config[SPACER]}${config[DB_NAME]};"

  # Print the database name
  echo "Database ${config[DB_PREFIX]}$i${config[SPACER]}${config[DB_NAME]} created"
done

# Print the completion message
echo "All users and databases created"
