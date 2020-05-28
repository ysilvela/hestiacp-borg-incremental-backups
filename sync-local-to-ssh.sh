#!/bin/bash
# перед запуском настраиваем параметры доступа к хранилищу ssh и обязательно должна уже быть настроена аутентификация по ssh ключам

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini


ssh $REMOTE_BACKUP_SERVER_USER@$REMOTE_BACKUP_SERVER mkdir -p $REMOTE_BACKUP_SERVER_DIR
rsync -v -a --delete -e 'ssh -T -o Compression=no -x' $BACKUP_DIR_LOCAL/ $REMOTE_BACKUP_SERVER_USER@$REMOTE_BACKUP_SERVER:$REMOTE_BACKUP_SERVER_DIR/


