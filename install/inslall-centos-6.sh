#!/bin/bash

cd 

virtualenv --python=python3 borg-env
source borg-env/bin/activate

pip install -U pip==19.0.3
pip install -U setuptools wheel

git clone https://github.com/thomaswaldmann/pyinstaller.git
pushd pyinstaller/
git checkout v3.5-maint
python setup.py install
popd

pip download borgbackup==1.1.13
tar -xvf borgbackup-1.1.13.tar.gz
pushd borgbackup-1.1.13
sed -i 's/vagrant\/borg\/borg/root\/borgbackup-1.1.13/' scripts/borg.exe.spec
pip install -r requirements.d/development.lock.txt
pip install -e .
pyinstaller --clean --distpath=/root/b scripts/borg.exe.spec
popd


# localectl set-locale LANG=en_US.utf8
localedef -c -i en_US -f UTF-8 en_US.UTF-8
yum install git -y 


wget https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper-0.9.5-2.el6.x86_64.rpm
rpm -Uvh mydumper-0.9.5-2.el6.x86_64.rpm

mkdir -p /var/log/scripts/backup 
crontab -l | { cat; echo '0 0 * * * /bin/sleep `/usr/bin/shuf -i 1-14400 -n 1` && /root/scripts/vestacp-borg-incremental-backups/backup-execute.sh > /var/log/scripts/backup/backup_`date "+\%Y-\%m-\%d"`.log 2>&1'; } | crontab -


