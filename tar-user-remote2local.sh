#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a web domain from incremental backup
USAGE='tar-user.sh user 2018-03-25'

# Assign arguments
TIME=$2
USER=$1


# Set script start time
START_TIME=`date +%s`

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####
if [ -z $1  ]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and web domain. Dadabase is optional"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ -z $2 ]; then
  borg list $USER_REPO
  exit 1
fi

mkdir -p echo /home/$USER/backups

borg export-tar $USER_REPO::$TIME /home/$USER/backups/$USER.$TIME.tar 
chown $USER: /home/$USER/backups/$USER.$TIME.tar

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
