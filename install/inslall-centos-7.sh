#!/bin/bash

localectl set-locale LANG=en_US.utf8
yum install borgbackup git -y 


yum install git glib2-devel mysql-devel zlib-devel pcre-devel openssl-devel cmake gcc-c++ -y 
mkdir -p ~/src/ && cd  ~/src/
git clone https://github.com/maxbube/mydumper
cd mydumper
cmake .
make
make install 


mkdir -p /var/log/scripts/backup 
crontab -l | { cat; echo '0 0 * * * /bin/sleep `/usr/bin/shuf -i 1-14400 -n 1` && /root/scripts/vestacp-borg-incremental-backups/backup-execute.sh > /var/log/scripts/backup/backup_`date "+\%Y-\%m-\%d"`.log 2>&1'; } | crontab -


