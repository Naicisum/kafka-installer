#!/bin/bash -       
#title           :update_checksums.sh
#description     :This script will update the conf checksums
#author          :Naicisum <Naicisum@users.noreply.github.com>
#date            :20190516
#version         :0.1
#usage           :bash update_checksums.sh
#notes           :
#==============================================================================

# Set Variables and Get Parameters from Config File
BASE_DIR=$(dirname $0)
CONF_DIR=$BASE_DIR/conf
DATA_DIR=$BASE_DIR/data

CONFIG_FILES=$(grep "_SHA1" $BASE_DIR/installer.properties | grep -v "_DATA_" | sed 's/_SHA1.*//')
DATA_FILES=$(grep "_SHA1" $BASE_DIR/installer.properties | grep -e "_DATA_" | sed 's/_SHA1.*//')

sub_yesno()
{
    read -p "[y/N]: " -r
    if [ "$REPLY" != "y" ]; then
        echo "User aborted!"
        exit 1
    fi
}

echo
echo "This script will update the SHA1 checksums for files in the CONF directory"
echo "that are stored inside the installer.properties files. This could cause"
echo "unexpected issues."
echo "Do you wish to continue?"
sub_yesno

echo
echo "Updating Checksums"
for file in $CONFIG_FILES;
do
    FILENAME=$(grep "$file=" $BASE_DIR/installer.properties | cut -d'=' -f2)
    echo -n "  $(echo $file)_SHA1 - "
    sed -i "s/^$(echo $file)_SHA1=.*/$(echo $file)_SHA1=$(sha1sum $CONF_DIR/$FILENAME | cut -d' ' -f1)/" $BASE_DIR/installer.properties
    echo "[DONE]"
done
for file in $DATA_FILES;
do
    FILENAME=$(grep "$file=" $BASE_DIR/installer.properties | cut -d'=' -f2)
    echo -n "  $(echo $file)_SHA1 - "
    sed -i "s/^$(echo $file)_SHA1=.*/$(echo $file)_SHA1=$(sha1sum $DATA_DIR/$FILENAME | cut -d' ' -f1)/" $BASE_DIR/installer.properties
    echo "[DONE]"
done
echo
