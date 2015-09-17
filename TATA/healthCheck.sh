#!/bin/bash

exceptionCount=`ssh -q root@10.10.10.201 "grep -c \"/getimage: java.io.IOException: GetImage failed. java.lang.NullPointerException\" /data/hadoop_logs/hadoop-admin-namenode-tata-br35-col-01.log”`
if [ -z $exceptionCount ]
then
(echo "Subject: Tata: NameNode process not running on Master NN";echo "From: tclmonitor@guavus.com";echo "To: ankur.gupta@guavus.com;noc.support@guavus.com;";echo "Content-Type: text/html";cat /data/body)|/usr/lib/sendmail -t
elif [ $exceptionCount -gt 0 ]
then
(echo "Subject: Tata: GetImage Failed Exceptions found in namenode logs";echo "From: tclmonitor@guavus.com";echo "To: ankur.gupta@guavus.com;noc.support@guavus.com;";echo "Content-Type: text/html";cat /data/body)|/usr/lib/sendmail -t
fi

for i in 131 132
do
vmState=`ssh -q root@10.10.10.$i "virsh list" | grep tata| awk '{print $NF}'`
if [ $vmState != "running" ]
then
host=`ssh -q root@10.10.10.$i "hostname"`
(echo "Subject: Tata: GMS vm not running on $host";echo "From: tclmonitor@guavus.com";echo "To: ankur.gupta@guavus.com;noc.support@guavus.com;";echo "Content-Type: text/html";cat /data/body)|/usr/lib/sendmail -t
fi
done

for i in 131 132
do
fsState=`ssh -q root@10.10.10.$i "/data/scripts/fsCheck.sh"`
if [ $fsState != "allgood" ]
then
host=`ssh -q root@10.10.10.$i "hostname"`
echo "Please check usage of following filesystem(s): --> $fsstate" > /data/body
(echo "Subject: Tata: FileSystem above 85% on $host";echo "From: tclmonitor@guavus.com";echo "To: ankur.gupta@guavus.com;noc.support@guavus.com;";echo "Content-Type: text/html";cat /data/body)|/usr/lib/sendmail -t
fi
done
