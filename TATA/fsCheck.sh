#!/bin/bash

/bin/df -hP > /data/df.txt
IFS='
'
probfs=""
for i in `cat /data/df.txt | grep -v ^Filesystem`
do
percentage=`echo $i | awk '{print $5}' | sed 's/%//'`
fsname=`echo $i | awk '{print $NF}'`
if [ $percentage -ge 85 ]
then
probfs=`echo "$probfs,$fsname"`
fi
done
if [ -z $probfs ]
then 
echo "allgood"
else
echo $probfs | sed 's/^,//'
fi
