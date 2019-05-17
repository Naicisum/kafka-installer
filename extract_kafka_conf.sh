#!/bin/bash -       
#title           :extract_kafka_conf.sh
#description     :This script will extract the config files from kafka archive
#author          :Naicisum <Naicisum@users.noreply.github.com>
#date            :20190516
#version         :0.1
#usage           :bash extract_kafka_conf.sh
#notes           :
#==============================================================================

# Set Variables and Get Parameters from Config File
BASE_DIR=$(dirname $0)
DATA_DIR=$BASE_DIR/data
CONF_DIR=$BASE_DIR/conf

KAFKA_FILENAME=$(cat $BASE_DIR/installer.properties | grep "FILE_DATA_KAFKA=" | cut -d'=' -f2)

sub_yesno()
{
    read -p "[y/N]: " -r
    if [ "$REPLY" != "y" ]; then
        echo "User aborted!"
        exit 1
    fi
}

echo
echo "This script will unpack the kafka and zookeeper config from the"
echo "archive $KAFKA_FILENAME"
echo "Do you wish to continue?"
sub_yesno

echo
echo "Extracting kafka configuration into CONF"
tar xvf $DATA_DIR/$KAFKA_FILENAME -C conf/ --strip-components=2 $(echo $KAFKA_FILENAME | sed 's/\.tgz//')/config/server.properties
echo "Updating checksum in installer.properties"
sed -i "s/^FILE_PROP_KAFKA_SHA1=.*$/FILE_PROP_KAFKA_SHA1=$(sha1sum $CONF_DIR/server.properties | cut -d' ' -f1)/" installer.properties

echo
echo "Extracting zookeeper configuration into CONF"
tar xvf $DATA_DIR/$KAFKA_FILENAME -C conf/ --strip-components=2 $(echo $KAFKA_FILENAME | sed 's/\.tgz//')/config/zookeeper.properties
echo "Updating checksum in installer.properties"
sed -i "s/^FILE_PROP_ZOO_SHA1=.*$/FILE_PROP_ZOO_SHA1=$(sha1sum $CONF_DIR/zookeeper.properties | cut -d' ' -f1)/" installer.properties

echo