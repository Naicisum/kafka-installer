Script to help install Kafka on CentOS/RHEL and install services

Requires OpenJDK 11 packages via standard yum repository
Requires commands: awk grep ip nslookup sed sha1sum sha512sum tar wget yum
Requires internet access to download kafka_2.12-2.2.0.tgz

Run 'get_kafka.sh' to download Kafka
Run 'extract_kafka_conf.sh' to extract the config files
Run 'install_kafka.sh' to begin install process

Unless you have read through and understand all the scripts and processes
do not use 'update_checksums.sh'
