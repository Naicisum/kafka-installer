#!/bin/bash -       
#title           :get_kafka.sh
#description     :This script will fetch Kafka from the internet to the current
#                 system.
#author          :Naicisum <Naicisum@users.noreply.github.com>
#date            :20190516
#version         :0.1
#usage           :bash get_kafka.sh
#notes           :
#==============================================================================

# Set Variables and Get Parameters from Config File
BASE_DIR=$(dirname $0)
DATA_DIR=$BASE_DIR/data

KAFKA_FILENAME=$(cat $BASE_DIR/installer.properties | grep "FILE_DATA_KAFKA=" | cut -d'=' -f2)
KAFKA_VERSION=$(echo $KAFKA_FILENAME | cut -d'-' -f2 | sed 's/\.tgz//')

KAFKA_URL_FILE="https://www.apache.org/dyn/closer.cgi?path=/kafka/$KAFKA_VERSION/$KAFKA_FILENAME"
KAFKA_URL_SHA512="https://www.apache.org/dist/kafka/$KAFKA_VERSION/$KAFKA_FILENAME.sha512"

echo
echo "Fetching list of mirrors for $KAFKA_FILENAME"
wget -q --show-progress $KAFKA_URL_FILE -O $DATA_DIR/mirrors.tmp
echo "Fetching $KAFKA_FILENAME from top mirror"
wget -q --show-progress $(grep $KAFKA_FILENAME $DATA_DIR/mirrors.tmp | head -n1 | sed 's/^.*>http/http/;s/tgz.*$/tgz/') -O $DATA_DIR/$KAFKA_FILENAME
rm -f $DATA_DIR/mirrors.tmp > /dev/null 2>&1

echo
echo "Fetching SHA512 Checksum for $KAFKA_FILENAME"
wget -q --show-progress $KAFKA_URL_SHA512 -O $DATA_DIR/checksum.sha512
cat $DATA_DIR/checksum.sha512 | tr -d '\n'| tr -d ' ' | tr '[:upper:]' '[:lower:]' | awk 'BEGIN{FS=":"}{print $2 "  " $1}' > $DATA_DIR/$KAFKA_FILENAME.sha512
rm -f $DATA_DIR/checksum.sha512 > /dev/null 2>&1

echo
echo -n "Checking File Integrity ... "
pushd $DATA_DIR  > /dev/null 2>&1
if sha512sum -c $KAFKA_FILENAME.sha512 > /dev/null 2>&1; then
    echo "[PASSED]"
    rm -f $KAFKA_FILENAME.sha512
else
    echo "[FAILED]"
    exit 1
fi
popd  > /dev/null 2>&1

echo
echo "Updating checksum in installer.properties"
sed -i "s/^FILE_DATA_KAFKA_SHA1=.*$/FILE_DATA_KAFKA_SHA1=$(sha1sum $DATA_DIR/$KAFKA_FILENAME | cut -d' ' -f1)/" installer.properties
echo