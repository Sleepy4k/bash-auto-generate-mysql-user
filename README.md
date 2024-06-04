# Auto generate mysql user

Generate user based on provided data as username, this script will generate mysql user with unique password
and add user privilege for each database prefixed with username, with example like test database

## Installation

### Using Git

- Clone this project from github using git

```bash
git clone https://github.com/Sleepy4k/bash-auto-generate-mysql-user.git
```

- Go to the project directory

```bash
cd bash-auto-generate-mysql-user
```

### Using Zip File

- Download from github web using this url

```bash
https://github.com/Sleepy4k/bash-auto-generate-mysql-user/archive/refs/heads/main.zip
```

- Unzip zip file

## How to use

- First you need to put some file on folder "data", inside file must be unique

- Second, run this script on bash terminal with argument up or down

- Argument up used to generate user, and down for revoking user

```bash
./main.sh <up | down>
```
