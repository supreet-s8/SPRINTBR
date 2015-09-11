#!/bin/bash
while true
do
	d=`date | awk '{print $2" "$3" "$4}'|cut -d: -f1`
	#d="Aug 26 11"
	out=`grep "$d" /var/log/messages | grep BinningDropDump | grep -v grep`
	if [[ $out ]]
	then
		#echo "exit"
		sed -i 's/^/#/g' /etc/cron.d/pcap 
		exit
	fi

done
