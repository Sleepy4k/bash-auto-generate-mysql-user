#!/bin/bash

# Set your MySQL root username and password
MYSQL_USER="root"
MYSQL_PASS=""

# Specify the domain prefix (username)
DOMAIN="2311102"

# Specify the domain suffix (username)
DOMAIN_START="1"
DOMAIN_END="10"

# Query constants
SPACER="_"
DEFAULT="test"

# Loop through the domain suffixes
for i in $(seq -f "%03g" $DOMAIN_START $DOMAIN_END)
do
  # if variable i length is less than domain end length then add 0 to the start of i
  if [ ${#i} -lt ${#DOMAIN_END} ]; then
    i="0$i"
  fi

  # Create the user
  mysql -u $MYSQL_USER -p $MYSQL_PASS -e "CREATE USER IF NOT EXISTS '$DOMAIN$i'@'localhost' IDENTIFIED BY '$DOMAIN$i';"

  # Print the user name
  echo "User $DOMAIN$i created"

  # Grant privileges
  mysql -u $MYSQL_USER -p $MYSQL_PASS -e "GRANT ALL PRIVILEGES ON $DOMAIN$i$SPACER.* TO '$DOMAIN$i'@'localhost';"

  # Print the privileges
  echo "Privileges granted for $DOMAIN$i$SPACER"

  # Create the database
  mysql -u $MYSQL_USER -p $MYSQL_PASS -e "CREATE DATABASE $DOMAIN$i$SPACER$DEFAULT;"

  # Print the database name
  echo "Database $DOMAIN$i$SPACER$DEFAULT created"
done

# Print the completion message
echo "All users and databases created"
