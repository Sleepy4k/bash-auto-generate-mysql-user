#!/bin/bash

# Init variable to store file path
file_path="data"

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
  [SPACER]="_"
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
if [ ! -f "$file_path/${config[TARGET_FILE]}" ]; then
  echo "File $file_path/${config[TARGET_FILE]} not found"
  exit 1
fi

# Check if the output file is exists
# if exists then remove the file inside the folder
if [ -f "output/${config[TARGET_FILE]}" ]; then
  rm output/${config[TARGET_FILE]}
fi

# Make function to make output file
# The output file will be named as the input file
# but with value "nim | password" for each line
function make_output_file() {
  # so we will create the output file
  # based on parameter passed to this function

  # Get the nim
  nim=$1

  # Get the password
  password=$2

  # Write the output to the file
  echo "$nim | $password" >> output/${config[TARGET_FILE]}
}

# Make function to generate random password
# generated password must be unique based on the nim
# for each nim, the password must be the same
# and length of the password must be 8 characters
# and return the password
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
# On this function we will pass the nim as the parameter
function create_user_database() {
  # Generate the password
  password=$(generate_password $1)

  # Create the user
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "CREATE USER IF NOT EXISTS '$1'@'${config[USER_HOST]}' IDENTIFIED BY '$password';"

  # Print the user name
  echo "User $1 created for host ${config[USER_HOST]}"

  # Grant privileges
  prefixed_db_name="$1${config[SPACER]}%"
  mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "GRANT ALL PRIVILEGES ON $prefixed_db_name.* TO '$1'@'${config[USER_HOST]}';"

  # Print the privileges
  echo "Privileges granted for $prefixed_db_name.* on host ${config[USER_HOST]}"

  # # Create the database
  # mysql -u ${config[DB_USERNAME]} -p${config[DB_PASSWORD]} -e "CREATE DATABASE IF NOT EXISTS $1${config[SPACER]}${config[DB_NAME]};"

  # # Print the database name
  # echo "Database $1${config[SPACER]}${config[DB_NAME]} created"

  # Call the function to make output file
  make_output_file $1 $password
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

    # Call the function
    create_user_database $nim
  done < $file
done

# Print the completion message
echo "All users and databases created"
