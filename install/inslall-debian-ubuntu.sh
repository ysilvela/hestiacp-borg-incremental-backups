#!/bin/bash

apt update && apt install -y borgbackup mydumper

mkdir -p /var/log/scripts/backup 
crontab -l | { cat; echo '0 0 * * * /bin/sleep `/usr/bin/shuf -i 1-14400 -n 1` && /root/scripts/hestiacp-borg-incremental-backups/backup-execute.sh > /var/log/scripts/backup/backup_`date "+\%Y-\%m-\%d"`.log 2>&1'; } | crontab -


