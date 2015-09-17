#!/bin/bash

ssh -q 10.10.10.201 "hadoop dfsadmin -report | head -12" > /data/output/tclhdfs.txt
a=`cat /data/output/tclhdfs.txt | grep "DFS Used%" | awk '{print $NF}' | sed 's/%//g'`

if [ $(bc <<< "$a >= 85") -eq 1 ]
then
sed -i 's/$/<\/br>/g' /data/output/tclhdfs.txt
(echo "Subject: TCL Hadoop Utilisation Status"; echo "From: tclmonitor@guavus.com"; echo "To: ankur.gupta@guavus.com"; echo "Content-Type: text/html"; cat /data/output/tclhdfs.txt) | /usr/lib/sendmail -t
fi
