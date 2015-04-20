#!/bin/bash 
#
COL1=192.168.0.67
COL2=192.168.0.70
CMP1=192.168.0.74
CMP2=192.168.0.77
CMP3=192.168.0.80
COL3=192.168.0.83
COL4=192.168.0.86
CMP4=192.168.0.90
CMP5=192.168.0.93
CMP6=192.168.0.96
SSH="ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for hosts in $COL1 $COL2 
do
$SSH root@$hosts '/opt/tms/bin/cli -t "en" "conf term" "sho runn full" ' | grep "/tps/process/oozie" > /tmp/oozie_conf_$hosts.cli
echo ""
done
diff -sq `ls /tmp/oozie_conf_*.cli`
