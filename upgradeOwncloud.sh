#!/bin/bash

# URL For latest update. Reference: http://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html
URL=http://download.owncloud.org/community/owncloud-latest.tar.bz2
# We are just using this for now. If it is problematic, logic exists on line 45-47 to parse a filename.
FILENAME=owncloud-latest.tar.bz2

#These are our config directories.
LABEL="owncloud"
NOW=$(date +"%m-%d-%y")
OWNCLOUDDIR=/home/owncloud/www
DATADIR=$OWNCLOUDDIR/data
CONFIGFILE=/home/owncloud/www/config/config.php
CONFIGBACKUP=/home/owncloud/config-$NOW.php
WWWBACKUPFILE="$LABEL-$NOW.tgz"


if [ ! `whoami` == 'root' ]; then
	echo 'This script must be run as root.';
	echo 'Quitting.'
	exit 0;
fi

#Running Backup First!
backup-owncloud.sh

echo -n 'Checking for configuration... '

if [ ! -f $CONFIGFILE ]; then
	echo "[FAILED]"
	echo ""
	echo "Could not locate the configuration file. Check and see if $CONFIGFILE actually exists. We need to back it up in order to do the upgrade"
	exit 1
fi

echo "[OK]"

if [ -d /tmp/owncloud ]; then
	echo -n "ownCloud temporary directory found. Removing it... "
	rm -vfr /tmp/owncloud
	rm -vf /tmp/owncloud*.bz2*
	echo '[OK]'
fi

# echo "Enter the URL for the upgrade. E.g., https://download.owncloud.org/community/owncloud-7.0.3.tar.bz2"


echo "Getting the upgrade package..."
# FILENAME=`echo $URL | cut -d '/' -f 5`
# TMPFILE=/tmp/$FILENAME
#wget $URL -O $TMPFILE

cd /tmp/
wget $URL
tar -xjf $FILENAME

echo 'This script will upgrade ownCloud. Do you wish to continue? [n/Y]'
read CHOICE
if [ ! $CHOICE == 'Y' ]; then
	echo "Quitting! Better luck next time."
	exit 0;
fi

echo "Putting owncloud in maintenance mode..."
php $OWNCLOUDDIR/occ maintenance:mode --on

# echo 'Shutting down Apache...'
# service apache2 stop

echo -n 'Unmounting the data directory...'
umount $DATADIR
echo '[OK]'

echo -n 'Backing up the configuration... '
cp -v $CONFIGFILE $CONFIGBACKUP
echo "[OK]"

if [ ! -f $CONFIGBACKUP ]; then
	echo "BACKUP FAILED! Quitting."
	exit 0
fi

#Rename the current www directory to www-timestamp.
echo -n "Disabling current ownCloud directory by renaming it with a timestamp..."
mv $OWNCLOUDDIR $OWNCLOUDDIR-$NOW/
echo "[OK]"

echo -n "Copying all the new files to the production directory..."
cp -vr /tmp/owncloud/ $OWNCLOUDDIR
echo "[OK]"

echo -n "Restoring the config.php file..."
cp -v $CONFIGBACKUP $CONFIGFILE
echo "[OK]"

# echo -n 'Remounting data directory...'
# mount --bind /mnt/raid/cloud/ /home/owncloud/www/data
# echo '[OK]'

if [ ! -d "$DATADIR" ]; then
	mkdir $DATADIR
fi

echo -n "Restroing all mount points..."
mount -a
echo "[OK]"

echo -n "Fixing Permissions..."
chown -R owncloud:owncloud /home/owncloud/
echo "[OK]"

echo -n "Restarting Apache"
service apache2 restart
echo "[OK]"

echo 'Use occ upgrade? (Press "N" to upgrade via a browser) [n/Y]'
read CHOICE
if [ $CHOICE == 'N' ]; then
	echo "OK! You're on your own then. Navigate to your cloud installation, and proceed with the upgrade manually."
	exit 0;
fi

php $OWNCLOUDDIR/occ upgrade

echo "All right Ace! All right! I'll see you next time!"
echo "...the circle is complete."
echo "bbdbdbdbdbd that's all folks!"
echo "Done."