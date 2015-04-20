#!/bin/bash


#NODELIST=`ls ../etc/profiles/${PROFILE}/*.prop -l | awk -F "/"  {'print $NF'} | sed -e 's/\.prop//'`
NTPSRV=`/opt/tms/bin/cli -t 'en' 'show ntp configured' | grep server | awk {'print $NF'} | head -1`
NODELIST="192.168.0.67 192.168.0.70 192.168.0.74 192.168.0.77 192.168.0.80 192.168.0.83 192.168.0.86 192.168.0.90 192.168.0.93 192.168.0.96"
SSH='ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -l root ';

for i in ${NODELIST}
do

  echo "Syncing NTP on node $i"

  $SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf term' 'no ntp enable' "
  $SSH ${i} "ntpdate ${NTPSRV}" 
  $SSH ${i} "/opt/tms/bin/cli -t 'en' 'conf term' 'ntp enable' "

  echo "Syncing HW Clock on node $i"

  $SSH ${i} "mount -o remount,rw / && [[ -L /dev/rtc ]] || ln -s /dev/rtc0 /dev/rtc" 
  $SSH ${i} "hwclock --systohc && hwclock --show && date"
  if [[ $? -ne 0 ]]
    then
    printf "Unable to setup HW clock on ${i}\n"
  fi
 
  echo "Removing Combiner class entry if present on node $i"

  $SSH ${i} "cp /opt/etc/oozie/AtlasCubes/SubscriberibIpPortCleanup.json /opt/etc/oozie/AtlasCubes/SubscriberibIpPortCleanup.json.orig"
  $SSH ${i} "perl -ni -e 'print unless /combinerClass/' /opt/etc/oozie/AtlasCubes/SubscriberibIpPortCleanup.json"    

  echo "Optimizing memory settings on $i" 
  $SSH ${i} "echo 'echo "131072" > /proc/sys/vm/min_free_kbytes' >> /etc/rc.local ; source /etc/rc.local"
  echo ; echo

done

for i in 67 70 83 86 
do
  echo "Verifying Backup HDFS on node 192.168.0.$i"
  RES=`$SSH 192.168.0.$i "/opt/tms/bin/cli -t 'en' 'conf t' 'internal query get - /tps/process/backup_hdfs/attribute/namenode/value'" | awk {'print $(NF-1)'}`
  if [[ $RES != "UNINIT" ]] ; then
  $SSH 192.168.0.$i "/opt/tps/bin/pmx.py register backup_hdfs; /opt/tps/bin/pmx.py set backup_hdfs namenode UNINIT;"
  fi
  RES=""
done



