#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a web domain from incremental backup
USAGE="./restore-web.sh 2018-03-25 username domain.com [database]"

# Assign arguments
TIME=$1
USER=$2
WEB=$3

# Set script start time
START_TIME=`date +%s`

# Temp dir setup
TEMP_DIR=$CURRENT_DIR/tmp
mkdir -p $TEMP_DIR

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER
USER_DIR="/home/$USER"

##### Validations #####

if [[ -z $1 || -z $2 ]] || [[ $1 != "list" && -z $3 ]]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and web domain. Dadabase is optional"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  echo "or"
  echo "./restore-web.sh list username domain.com"
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER" ]; then
  echo "!!!!! User $USER does not exist"
  echo "---"
  echo "Available users:"
  ls $HOME_DIR
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER/web/$WEB" ]; then
  echo "!!!!! The web domain $WEB does not exist under user $USER."
  echo "---"
  echo "User $USER has the following available web domains:"
  ls $HOME_DIR/$USER/web
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi


if ! borg list $USER_REPO | grep -q $TIME; then
  echo "!!!!! Backup archive $TIME not found, the following are available:"
  borg list $USER_REPO
  echo "Usage example:"
  echo $USAGE
  exit 1
fi


echo "########## BACKUP ARCHIVE $TIME FOUND, PROCEEDING WITH RESTORE ##########"

read -p "Are you sure you want to restore web $WEB owned by $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi


# монтируем папку с бекапом, если не примонтирована
echo "----- Mount backup dir"
mkdir -p $USER_DIR/backups/$TIME
isMounted=`mount | grep borgfs | grep $USER_DIR/backups/$TIME`
if [ -z "$isMounted" ] ; then
  if ! borg mount $USER_REPO::$TIME $USER_DIR/backups/$TIME ; then
      echo "Borg mount failed. Try use restore-web.sh"
      exit 2
  fi
fi
 

# Set dir paths
WEB_DIR=$HOME_DIR/$USER/web/$WEB/$PUBLIC_HTML_DIR_NAME
BACKUP_WEB_DIR=$USER_DIR/backups/$TIME$HOME_DIR/$USER/web/$WEB/$PUBLIC_HTML_DIR_NAME
echo $BACKUP_WEB_DIR

echo "-- Rsync files start"
rsync -v -a --numeric-ids --delete $BACKUP_WEB_DIR/ $WEB_DIR/
echo "-- Rsync files finish"

echo "-- Fixing permissions"
chown -R $USER:$USER $WEB_DIR/

# Check if database argument is present and proceed with database restore

if [ $4 ]; then
  DB=$4
  v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}' | while read DATABASE ; do
    if [ "$DB" == "$DATABASE" ]; then
      echo "-- Restoring database $DB from backup $USER_REPO::$TIME"
      DB_DIR=$USER_DIR/backups/$TIME$HOME_DIR/$USER/$DB_DUMP_DIR_NAME
      # Check that the files have been restored correctly
      DB_FILE=$DB_DIR/$DB.sql.gz
      mv -f $WEB_DIR/.htaccess $WEB_DIR/.htaccess.backup
      echo "Deny From All" > $WEB_DIR/.htaccess
      $CURRENT_DIR/inc/db-restore.sh $DB $DB_FILE $DB_DIR
      mv -f $WEB_DIR/.htaccess.backup $WEB_DIR/.htaccess
    else
      echo "!!!!! Database $DB not found under selected user. User $USER has the following databases:"
      v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}'
    fi
  done
fi

echo "----- Umount backup dir"
borg umount $USER_DIR/backups/$TIME

echo
echo "$(date +'%F %T') ########## WEB $WEB OWNED BY $USER RESTORE COMPLETED ##########"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
