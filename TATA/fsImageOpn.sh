#!/bin/bash

fsimageTime=`ssh -q root@10.10.10.201 "stat /data/drbd/name/current/fsimage" | grep Change: | awk -F: '{print $2":"$3":"$4}' | awk -F. '{print $1}'`
fsimageTS=`date --date "$fsimageTime" +%s`
currentTS=`date +%s`
diffTS=`echo "$currentTS-$fsimageTS" | bc`
copyTime=`date +%Y-%m-%d-%H:%M`

scp -q root@10.10.10.201:/data/drbd/name/current/fsimage /data/fsimageBackup/fsimage.$copyTime
gzip /data/fsimageBackup/fsimage.$copyTime

if [ $diffTS -ge 86400 ]
then
(echo "Subject: Tata Mgm Node: fsimage not updated in last 24 hours";echo "From: tclmonitor@guavus.com";echo "To: ankur.gupta@guavus.com;noc.support@guavus.com";echo "Content-Type: text/html";cat /data/body)|/usr/lib/sendmail -t
fi
