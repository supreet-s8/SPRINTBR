#!/bin/bash
year=`date --date "15 days ago" +%Y`
month=`date --date "15 days ago" +%m`
day=`date --date "15 days ago" +%d`
deldate=`date --date "15 days ago" +%Y-%m-%d`

echo "====> `date` <====" 
echo " " 
echo "Netflow to be deleted for day: $year-$month-$day" 
ssh -q root@10.10.10.201 "hadoop fs -rmr /data/collectorA/netflow/$year/$month/$day" 
ssh -q root@10.10.10.201 "hadoop fs -rmr /data/collectorB/netflow/$year/$month/$day" 
ssh -q root@10.10.10.201 "hadoop fs -rmr /data/collectorA/ipfix/$year/$month/$day" 
ssh -q root@10.10.10.201 "hadoop fs -rmr /data/collectorB/ipfix/$year/$month/$day" 

ssh -q root@10.10.10.201 "hadoop fs -ls /data/routing/asib ; hadoop fs -ls /data/routing/eib ; hadoop fs -ls /data/routing/mergedib ; hadoop fs -ls /data/_BizreflexCubes/Gleaning/ " > /tmp/hdfsib.txt 

IFS='
'
delpath=`cat /tmp/hdfsib.txt | grep $deldate | awk '{print $8}' | tr '\n' ' '`
if [[ ! -z $delpath ]]
then
echo "hadoop fs -rm $delpath" 
fi

delbview=`ssh -q root@10.10.10.201 "find /data/routing/bgp/ -mtime +15 -type f"`
