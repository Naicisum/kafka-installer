#!/bin/bash -       
#title           :install_kafka.sh
#description     :This script will install Kafka on the current system.
#author          :Naicisum <Naicisum@users.noreply.github.com>
#date            :20190516
#version         :0.3
#usage           :bash install_kafka.sh
#notes           :
#==============================================================================

# Set Variables and Get Parameters from Config File
BASE_DIR=$(dirname $0)
. $BASE_DIR/installer.properties
DATA_DIR=$BASE_DIR/data
CONF_DIR=$BASE_DIR/conf
FAILURES=0

# Common Functions
sub_checkroot()
{
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 
        exit 1
    fi
}

sub_vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

sub_readinput()
{
    local __inputvar=$1
    read -p "[$(eval echo $(echo "$"$__inputvar))]: " -r
    if [ "$REPLY" != "" ]; then
        eval $__inputvar=$REPLY
    fi
}

sub_resolvehost()
{
    local __inputvar=$1
    local __hostname=$(ip route get 1 | awk '{for(i=1;i<=NF;i++)if(match("src",$i)){print $(i+1)}}' | nslookup | grep name | cut -d'=' -f2 | sed 's/ //g;s/\.$//')
    if [ "$__hostname" == "" ]; then
        __hostname=$(hostname -f | sed 's/ //g')
    fi
    if [ "$__hostname" != "" ]; then
        eval $__inputvar=$__hostname:2181
    fi
}

sub_resolvebroker()
{
    local __inputval=$1
    local __hostsval=$2
    local __numhosts=$(echo ${!__hostsval} | awk 'BEGIN {FS=","}{print NF}')
    for (( i=1; i <= $__numhosts; i++ ))
    do
        local __hostname=$(ip route get 1 | awk '{for(i=1;i<=NF;i++)if(match("src",$i)){print $(i+1)}}' | nslookup | grep name | cut -d'=' -f2 | sed 's/ //g;s/\.$//')
        if [ "$__hostname" == "" ]; then
            __hostname=$(hostname -f | sed 's/ //g')
        fi
        local __singlehost=$(echo ${!__hostsval} | awk -v i="$i" 'BEGIN {FS=","}{print $i}' | sed 's/:2181//g')
        if [ "$__hostname" == "$__singlehost" ]; then
            eval $__inputval=$i
        fi
    done
}

sub_addbrokers()
{
    local __inputval=$1
    local __zooconf=$2
    local __numhosts=$(echo ${!__inputval} | awk 'BEGIN {FS=","}{print NF}')
    echo >> $__zooconf
    for (( i=1; i <= $__numhosts; i++ ))
    do
        local __singlehost=$(echo ${!__inputval} | awk -v i="$i" 'BEGIN {FS=","}{print $i}' | sed 's/:2181//g')
        echo "server.$i=$__singlehost:2888:3888" >> $__zooconf
    done
}

sub_checkfile()
{
    local __inputval=$1
    local __sha1val=$2
    echo -n "  Checking $__inputval - ["
    if [ ! -f $__inputval ]; then
        echo -n "FAILED"
        ((FAILURES++))
    else
        local __sha1sum=$(sha1sum $1 | cut -d' ' -f1)
        if [ "$__sha1sum" == "$2" ]; then 
            echo -n "PASSED"
        else
            echo -n "FAILED"
            ((FAILURES++))
        fi
    fi
    echo "]"
}

sub_checkrepo()
{
    local __inputval=$1
    echo -n "  Checking $__inputval - ["
    if ! yum -q search $__inputval > /dev/null 2>&1; then
        echo -n "FAILED"
        ((FAILURES++))
    else
        echo -n "PASSED"
    fi
    echo "]"
}

sub_yesno()
{
    read -p "[y/N]: " -r
    if [ "$REPLY" != "y" ]; then
        echo "User aborted!"
        exit 1
    fi
}

sub_failures()
{
    if [ $FAILURES != 0 ]; then
        echo "Failures detected, aborting!"
        exit 1
    fi
}

sub_sanitycheck()
{
    echo
    echo "Sanity Checking"

    sub_checkrepo $REPO_DATA_JDK
    sub_checkfile $DATA_DIR/$FILE_DATA_KAFKA $FILE_DATA_KAFKA_SHA1
    
    sub_checkfile $CONF_DIR/$FILE_SERVICE_KAFKA $FILE_SERVICE_KAFKA_SHA1
    sub_checkfile $CONF_DIR/$FILE_SERVICE_ZOO $FILE_SERVICE_ZOO_SHA1

    sub_checkfile $CONF_DIR/$FILE_PROP_KAFKA $FILE_PROP_KAFKA_SHA1
    sub_checkfile $CONF_DIR/$FILE_PROP_ZOO $FILE_PROP_ZOO_SHA1

    sub_checkfile $CONF_DIR/$FILE_SERV_KAFKA $FILE_SERV_KAFKA_SHA1
    sub_checkfile $CONF_DIR/$FILE_SERV_ZOO $FILE_SERV_ZOO_SHA1
    
    sub_failures
}

sub_getpaths()
{
    echo
    echo "In which directory do you want to install Kafka?"
    sub_readinput PATH_INSTALL

    PATH_KAFKA_DATA=$PATH_INSTALL/data/kafka-logs
    PATH_ZOO_DATA=$PATH_INSTALL/data/zookeeper

    echo
    echo "In which directory do you want to install Kafka conf?"
    sub_readinput PATH_KAFKA_CONF

    echo
    echo "In which directory do you want to install Zookeeper conf?"
    sub_readinput PATH_ZOO_CONF

    echo
    echo "In which directory do you want to install service files?"
    sub_readinput PATH_SERVICE

    echo
    echo "In which directory do you want to use for Kafka Data?"
    sub_readinput PATH_KAFKA_DATA

    echo
    echo "In which directory do you want to use for Zookeeper Data?"
    sub_readinput PATH_ZOO_DATA

    echo
    echo "How much memory to allocate in GB to the Zookeeper Java Heap?"
    sub_readinput CONF_ZOO_MEMORY

    echo
    echo "How much memory to allocate in GB to the Kafka Java Heap?"
    sub_readinput CONF_KAFKA_MEMORY

    echo
    echo "Provide the Zookeeper names Kafka will use. This is a comma"
    echo "separated host:port pairs, each corresponding to a zookeeper server."
    echo "e.g. \"host1.fqdn.tld:2181,host2.fqdn.tld:2181,host3.fqdn.tld:2181\""
    sub_resolvehost CONF_KAFKA_ZOOHOSTS
    sub_readinput CONF_KAFKA_ZOOHOSTS

    echo
    echo "Enter Zookeeper Broker ID"
    sub_resolvebroker CONF_ZOO_BROKERID CONF_KAFKA_ZOOHOSTS
    sub_readinput CONF_ZOO_BROKERID
}

sub_verifypaths()
{
    echo
    echo "Verify Paths"
    echo "  Kafka Path           :  $PATH_INSTALL"
    echo "  Kafka Conf           :  $PATH_KAFKA_CONF"
    echo "  Zookeeper Conf       :  $PATH_ZOO_CONF"
    echo "  Service Path         :  $PATH_SERVICE"
    echo "  Kafka Data           :  $PATH_KAFKA_DATA"
    echo "  Zookeeper Data       :  $PATH_ZOO_DATA"
    echo
    echo "Verify Configs"
    echo "  Zookeeper Heap GB    :  $CONF_ZOO_MEMORY"
    echo "  Kafka Heap GB        :  $CONF_KAFKA_MEMORY"
    echo "  Kafka ZK Hosts       :  $CONF_KAFKA_ZOOHOSTS"
    echo "  Zookeeper Broker Id  :  $CONF_ZOO_BROKERID"
    echo
    echo "Are the statements above correct?"
    sub_yesno
}

sub_setalternative()
{
    local __packagename=$1
    local __packagebin=$(rpm -ql $(echo $__packagename | sed 's/devel/headless/') | grep -e "/java$")
    echo "  Setting java default to [$__packagename] via alternatives"
    alternatives --set java $__packagebin
}

sub_installjdk()
{

    echo "Checking if [$REPO_DATA_JDK] is installed"
    if yum list installed "$REPO_DATA_JDK" > /dev/null 2>&1; then
        echo "  Package Installed, setting as default java"
        sub_setalternative $REPO_DATA_JDK
    else
        echo "  Package Missing, installing via yum and setting as default java"
        yum -q -y install $REPO_DATA_JDK > /dev/null 2>&1
        sub_setalternative $REPO_DATA_JDK
    fi
}

sub_installkafka()
{
    echo
    echo "Installing Kafka from [$FILE_DATA_KAFKA]"
    if [ ! -d $PATH_INSTALL ]; then
        echo "  Creating directory"
        mkdir -p $PATH_INSTALL
        tar -xf $DATA_DIR/$FILE_DATA_KAFKA -C $PATH_INSTALL --strip 1
        echo "  Files Installed"
    else
        echo "  Directory Exists / Bypassed"
    fi    
}

sub_installconfzoo()
{
    echo
    echo "Installing Zookeeper Config into [$PATH_ZOO_CONF]"
    if [ ! -d $PATH_ZOO_CONF ]; then
        echo "  Creating directory"
        mkdir $PATH_ZOO_CONF
        echo "  Copying config files"
        cp $CONF_DIR/$FILE_PROP_ZOO $PATH_ZOO_CONF/$FILE_PROP_ZOO
        cp $CONF_DIR/$FILE_SERV_ZOO $PATH_ZOO_CONF/$(echo $FILE_SERV_ZOO | cut -d'_' -f2)
        echo "  Updating SERVICE_HOME to [$PATH_INSTALL] in [$(echo $FILE_SERV_ZOO | cut -d'_' -f2)]"
        sed -i "s/^SERVICE_HOME=.*$/SERVICE_HOME=$(echo $PATH_INSTALL | sed 's/\//\\\//g')/" $PATH_ZOO_CONF/$(echo $FILE_SERV_ZOO | cut -d'_' -f2)
        echo "  Updating SERVICE_CONF to [$PATH_ZOO_CONF] in [$(echo $FILE_SERV_ZOO | cut -d'_' -f2)]"
        sed -i "s/^SERVICE_CONF=.*$/SERVICE_CONF=$(echo $PATH_ZOO_CONF | sed 's/\//\\\//g')/" $PATH_ZOO_CONF/$(echo $FILE_SERV_ZOO | cut -d'_' -f2)
        echo "  Updating Java Heap to [$CONF_ZOO_MEMORY] in [$(echo $FILE_SERV_ZOO | cut -d'_' -f2)]"
        sed -i "s/^KAFKA_HEAP_OPTS=.*$/KAFKA_HEAP_OPTS=\"-Xmx${CONF_ZOO_MEMORY}G -Xms${CONF_ZOO_MEMORY}G\"/" $PATH_ZOO_CONF/$(echo $FILE_SERV_ZOO | cut -d'_' -f2)
        echo "  Updating Data directory to [$PATH_ZOO_DATA] in [$FILE_PROP_ZOO]"
        sed -i "s/^dataDir=.*$/dataDir=$(echo $PATH_ZOO_DATA | sed 's/\//\\\//g')/" $PATH_ZOO_CONF/$FILE_PROP_ZOO
        echo "  Adding Zookeeper Brokers in [$FILE_PROP_ZOO]"
        sub_addbrokers CONF_KAFKA_ZOOHOSTS "$PATH_ZOO_CONF/$FILE_PROP_ZOO"
        echo "  Creating Data directory"
        mkdir -p $PATH_ZOO_DATA
        echo "  Setting Local Broker ID to [$CONF_ZOO_BROKERID]"
        echo "$CONF_ZOO_BROKERID">$PATH_ZOO_DATA/myid
    else
        echo "  Directory Exists / Bypassed"
    fi
}

sub_installconfkafka()
{
    echo
    echo "Installing Kafka Config into [$PATH_KAFKA_CONF]"
    if [ ! -d $PATH_KAFKA_CONF ]; then
        echo "  Creating directory"
        mkdir $PATH_KAFKA_CONF
        echo "  Copying config files"
        cp $CONF_DIR/$FILE_PROP_KAFKA $PATH_KAFKA_CONF/$FILE_PROP_KAFKA
        cp $CONF_DIR/$FILE_SERV_KAFKA $PATH_KAFKA_CONF/$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)
        echo "  Updating SERVICE_HOME to [$PATH_INSTALL] in [$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)]"
        sed -i "s/^SERVICE_HOME=.*$/SERVICE_HOME=$(echo $PATH_INSTALL | sed 's/\//\\\//g')/" $PATH_KAFKA_CONF/$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)
        echo "  Updating SERVICE_CONF to [$PATH_KAFKA_CONF] in [$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)]"
        sed -i "s/^SERVICE_CONF=.*$/SERVICE_CONF=$(echo $PATH_KAFKA_CONF | sed 's/\//\\\//g')/" $PATH_KAFKA_CONF/$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)
        echo "  Updating Java Heap to [$CONF_KAFKA_MEMORY] in [$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)]"
        sed -i "s/^KAFKA_HEAP_OPTS=.*$/KAFKA_HEAP_OPTS=\"-Xmx${CONF_KAFKA_MEMORY}G -Xms${CONF_KAFKA_MEMORY}G\"/" $PATH_KAFKA_CONF/$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)
        echo "  Updating Data directory to [$PATH_KAFKA_DATA] in [$FILE_PROP_KAFKA]"
        sed -i "s/^log\.dirs=.*$/log\.dirs=$(echo $PATH_KAFKA_DATA | sed 's/\//\\\//g')/" $PATH_KAFKA_CONF/$FILE_PROP_KAFKA
        echo "  Updating Local Broker Id to [$CONF_ZOO_BROKERID] in [$FILE_PROP_KAFKA]"
        sed -i "s/^broker\.id=.*$/broker\.id=$CONF_ZOO_BROKERID/" $PATH_KAFKA_CONF/$FILE_PROP_KAFKA
        echo "  Updating Zookeeper Hosts to [$CONF_KAFKA_ZOOHOSTS] in [$FILE_PROP_KAFKA]"
        sed -i "s/^zookeeper\.connect=.*$/zookeeper\.connect=$CONF_KAFKA_ZOOHOSTS/" $PATH_KAFKA_CONF/$FILE_PROP_KAFKA
        echo "  Creating Data directory"
        mkdir -p $PATH_KAFKA_DATA
    else
        echo "  Directory Exists / Bypassed"
    fi
}

sub_installservices()
{
    echo
    echo "Installing Services info [$PATH_SERVICE]"
    if [ ! -f $PATH_SERVICE/$FILE_SERVICE_ZOO ]; then
        cp $CONF_DIR/$FILE_SERVICE_ZOO $PATH_SERVICE
        echo "  Zookeeper Service Installed"
        echo "  Updating EnvironmentFile in [$FILE_SERVICE_ZOO]"
        sed -i "s/^EnvironmentFile=.*$/EnvironmentFile=$(echo $PATH_ZOO_CONF | sed 's/\//\\\//g')\/$(echo $FILE_SERV_ZOO | cut -d'_' -f2)/" $PATH_SERVICE/$FILE_SERVICE_ZOO
    else
        echo "  Zookeeper Service already exists, bypassing copy"
    fi
    if [ ! -f $PATH_SERVICE/$FILE_SERVICE_KAFKA ]; then
        cp $CONF_DIR/$FILE_SERVICE_KAFKA $PATH_SERVICE
        echo "  Kafka Service Installed"
        echo "  Updating EnvironmentFile in [$FILE_SERVICE_KAFKA]"
        sed -i "s/^EnvironmentFile=.*$/EnvironmentFile=$(echo $PATH_KAFKA_CONF | sed 's/\//\\\//g')\/$(echo $FILE_SERV_KAFKA | cut -d'_' -f2)/" $PATH_SERVICE/$FILE_SERVICE_KAFKA
    else
        echo "  Kafka Service already exists, bypassing copy"
    fi

    echo "  Reloading service daemon"
    systemctl daemon-reload
}

# Script Begin
echo "Kafka Install Script"

sub_checkroot
sub_sanitycheck
sub_getpaths
sub_verifypaths

echo
echo "Beginning Installation"

sub_installjdk
sub_installkafka
sub_installconfzoo
sub_installconfkafka
sub_installservices

echo
echo "End Kafka Install Script"
