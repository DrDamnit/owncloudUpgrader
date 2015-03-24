#!/bin/bash
# Reference: http://doc.owncloud.org/server/7.0/admin_manual/maintenance/backup.html
SOURCEDIR=/home/owncloud/www
BACKUPDIR=/root/backups/owncloud_`date +"%Y%m%d"`/
DBBACKUPPATH="$BACKUPDIR"mysqldump_`date +"%Y%m%d"`.sql
MYSQLUSER=owncloud
MYSQLPASS=[CHANGEME]
MYSQLSERVER=localhost
MYSQLDBNAME=owncloud
clear

echo "Current Config:"
echo "Source Dir: $SOURCEDIR"
echo -n "Backup Dir: $BACKUPDIR"
if [ ! -d "$BACKUPDIR" ]; then
	echo " <---(Will be created)"
else
	echo ""
fi
echo "Dump Path:  $DBBACKUPPATH"
echo ""
echo "Proceed? [y/N]"
read CHOICE
if [ "$CHOICE" != "Y" ] && [ "$CHOICE" != "y" ]; then
	exit 1
fi

#Create Backup Directory
if [ ! -d "$BACKUPDIR" ]; then
	mkdir -p $BACKUPDIR
fi

if [ ! -d "$BACKUPDIR" ]; then
    echo "Could not create backup directory!"
    exit 1
fi

#Dump MySQL into the datadir before backup.
mysqldump --lock-tables -h $MYSQLSERVER -u$MYSQLUSER -p$MYSQLPASS $MYSQLDBNAME > $DBBACKUPPATH
echo "Unmounting data (if mounted)..."
umount /home/owncloud/www/data
#Backup directories with rsync:
echo "Backing up to: $BACKUPDIR"
rsync -Avax $SOURCEDIR $BACKUPDIR
echo "Restoring Mounts"
mount -a
