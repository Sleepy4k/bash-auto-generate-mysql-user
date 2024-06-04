#!/bin/bash

# Handle arguments passed to the script
category=$1

# Make function to print the usage
#
# Return:
# void
function print_usage() {
  echo "===================================="
  echo "Argument category is required"
  echo "Usage: ./insert.sh <category>"
  echo "Category: <up | down>"
  echo "Example: ./insert.sh up"
  echo "===================================="
}

# Check if the category is empty
if [ -z "$category" ]; then
  print_usage
  echo "Program exited"
  exit 1
fi

# Check if the category is not up or down
if [ "$category" != "up" ] && [ "$category" != "down" ]; then
  print_usage
  echo "Program exited"
  exit 1
fi

# Init variable to store file path
file_path="data"

# Init variable to store output path
output_path="output"

# Init array to store configuration
typeset -A config

# Init array to store generated password for each file
typeset -A generated_password

# Set default values, please do not change this
# except you know what you are doing
# This is the default configuration
config=(
  [DB_USERNAME]="root"
  [DB_PASSWORD]=""
  [DB_NAME]="test"
  [USER_HOST]="localhost"
  [TARGET_FILE]="nim_kelas_test.txt"
)

# Read the configuration file and set the values from generate.conf
# If the configuration file is not found, use the default values
# If the configuration file is found, override the default values
while IFS='=' read -r key value; do
  # If the line is empty, or if key and value is empty, then skip
  if [ -z "$key" ] || [ -z "$value" ]; then
    continue
  fi

  # Unwrap the value
  value=$(echo $value | sed 's/^"\(.*\)"$/\1/')

  # Set the value to the key
  config[$key]=$value
done < generate.conf

# Check if there is any file exists with the pattern
# from file_path variable and target_file variable
if [ "$category" == "up" ] && [ ! -f "$file_path/${config[TARGET_FILE]}" ]; then
  echo "File $file_path/${config[TARGET_FILE]} not found"
  exit 1
fi

# Check if the output file is exists
# if exists then remove the file inside the folder
# but only remove when category is up
if [ "$category" == "up" ] && [ -f "$output_path/${config[TARGET_FILE]}" ]; then
  # Print the message that we are deleting the file
  echo "Deleting file $output_path/${config[TARGET_FILE]}"

  # Remove the file in try catch block
  rm $output_path/${config[TARGET_FILE]} || {
    echo "Failed to delete file $output_path/${config[TARGET_FILE]}"
    exit 1
  }

  # Print the message if the file is deleted
  echo "File $output_path/${config[TARGET_FILE]} deleted"
fi

# Make function to make output file
# The output file will be named as the input file
# but with value "nim | password" for each line
#
# Parameter:
# $1: nim
# $2: password
#
# Return:
# void
function make_output_file() {
  # so we will create the output file
  # based on parameter passed to this function
  # the parameter is nim and password

  # Get the nim
  nim=$1

  # Get the password
  password=$2

  # Write the output to the file
  echo "$nim | $password" >> $output_path/${config[TARGET_FILE]}
}

# Make function to generate random password
# generated password must be unique based on the nim
# for each nim, the password must be the same
# and length of the password must be 8 characters
# and return the password
#
# Parameter:
# $1: nim
#
# Return:
# string - generated password
function generate_password() {
  # Generate the password
  password=$(echo $1 | sha256sum | base64 | head -c 8)

  # Check if generated password is already generated
  # using loop to check if the password is already generated
  # if the password is already generated, then generate the password again
  # until the password is unique
  while [ -n "${generated_password[$password]}" ]; do
    if [ "${generated_password[$password]}" != "$1" ]; then
      # If the password is already generated
      # then generate the password again
      # until the password is unique
      password=$(echo $1 | sha256sum | base64 | head -c 8)
      continue
    fi
  done

  # Store the generated password to the array
  generated_password[$password]=$1

  # Return the password
  echo $password
}

# Make function to create user, database, and grant privileges
#
# Parameter:
# $1: nim
#
# Return:
# void
function create_user_database() {
  # Generate the password
  password=$(generate_password $1)

  # Create the user
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "CREATE USER IF NOT EXISTS '$1'@'${config[USER_HOST]}' IDENTIFIED BY '$password';"

  # Print the user name
  echo "User $1 created for host ${config[USER_HOST]}"

  # Grant privileges
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "GRANT ALL PRIVILEGES ON \`$1\_%\`.* TO '$1'@'${config[USER_HOST]}';"

  # Print the privileges
  echo "Privileges granted for $1\_%.* on host ${config[USER_HOST]}"

  # Create the database
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "CREATE DATABASE IF NOT EXISTS $1_${config[DB_NAME]};"

  # Print the database name
  echo "Database $1_${config[DB_NAME]} created"

  # Call the function to make output file
  make_output_file $1 $password
}

# Make function to drop user, database, and revoke privileges
#
# Parameter:
# $1: nim
#
# Return:
# void
function drop_user_database() {
  # Drop the database
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "DROP DATABASE IF EXISTS $1${config[SPACER]}${config[DB_NAME]};"

  # Print the database name
  echo "Database $1${config[SPACER]}${config[DB_NAME]} dropped"

  # Revoke privileges
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "REVOKE ALL PRIVILEGES ON \`$1\_%\`.* FROM '$1'@'${config[USER_HOST]}';"

  # Print the privileges
  echo "Privileges revoked for \`$1\_%\`.* on host ${config[USER_HOST]}"

  # Drop the user
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "DROP USER IF EXISTS '$1'@'${config[USER_HOST]}';"

  # Print the user name
  echo "User $1 dropped for host ${config[USER_HOST]}"
}

# Read content from file on data folder
for file in $file_path/${config[TARGET_FILE]}; do
  # Check if the file is empty
  if [ ! -s $file ]; then
    echo "File $file is empty"
    continue
  fi

  # Loop through the file
  while IFS= read -r line; do
    nim=$(echo $line | cut -d ' ' -f 1)

    # Check category data
    # if category is up then create user and database
    # if category is down then drop user and database
    if [ "$category" == "up" ]; then
      create_user_database $nim
    elif [ "$category" == "down" ]; then
      drop_user_database $nim
    fi
  done < $file
done

# Print the completion message
if [ "$category" == "up" ]; then
  echo "All users and databases created"
elif [ "$category" == "down" ]; then
  echo "All users and databases dropped"
fi
