#!/bin/bash

log=/data/scripts/
IP=$1
ssh1="ssh -q root@${IP} "
check=`$ssh1 "/opt/tms/bin/cli -m config -t 'show pm process collector'" | grep status | awk -F: '{print $NF}'`
if [ -f ${log}log.txt ]
then
	rm -f ${log}log.txt
fi

if [ $check == running ]
then
	
	top1=`$ssh1 "/usr/bin/top -b -p 21433 -n 1"` 
	drop_flow=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow dropped-flow'"`
	avg_flow_rate=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow average-flow-rate'"`
	binning_flow=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow dropped-expired-binning-flow'"`
	total_flow=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow total-flow'"`

	tf_day=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow total-flow interval-type 1-day interval-count 1'"|tail -1|awk '{print $NF}'`
	df_day=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow dropped-flow interval-type 1-day interval-count 1'"|tail -1|awk '{print $NF}'`

	dt=`$ssh1 "/opt/tms/bin/cli -m config -t 'collector stats instance-id 1 adaptor-stats netflow total-flow interval-type 1-day interval-count 1'"|tail -1|awk '{print $2}'`
	
	drop_flow_day=`echo "scale=3;$df_day * 100 / $tf_day"|bc`

	echo "TOP COMMAND OUTPUT" >> ${log}log.txt
	echo "$top1" >> ${log}log.txt
	echo "" >> ${log}log.txt

	kfps=`expr $avg_flow_rate / 1000`
	
	#drop_percent=`scale=10;expr $drop_flow \* 100 / $total_flow`
	drop_percent=`echo "scale=3;$drop_flow * 100 / $total_flow"|bc`
	
	binning_percent=`echo "scale=3;$binning_flow * 100 / $total_flow"|bc`

	echo "% Dropped-flow = ${drop_percent}%" >> ${log}log.txt

	echo "Current KFPS = $kfps" >> ${log}log.txt

	echo "% Dropped-expired-binning-flow = ${binning_percent}%" >> ${log}log.txt

	if [ -f ${log}exprd.txt ]
	then

		pre_binning_flow=`cat ${log}exprd.txt`
		if [ $binning_flow -eq $pre_binning_flow ]
		then
			echo "NO change in expired-binning-flow" >> ${log}log.txt
			echo $binning_flow > ${log}exprd.txt
		else
			change=`expr $binning_flow - $pre_binning_flow`
			echo "Expired-binning-flow increased by $change flows" >> ${log}log.txt
			echo $binning_flow > ${log}exprd.txt
		fi

	else 
		echo $binning_flow > ${log}exprd.txt
	fi

	echo "" >> ${log}log.txt
	echo "------------------------" >> ${log}log.txt

	echo "STATS FOR DATE $dt" >> ${log}log.txt	
	echo "" >> ${log}log.txt
	echo "Total-Flow = $tf_day" >> ${log}log.txt

	echo "Dropped-Flow = $df_day" >> ${log}log.txt

	echo "% Dropped-Flow = ${drop_flow_day}%" >> ${log}log.txt
	echo "------------------------" >> ${log}log.txt
 
else

	echo "Collector is not running" >> ${log}log.txt

fi

if [ -f ${log}log.txt ]
then

	cat  ${log}log.txt | /bin/mail -s "NTT BR COLLECTOR STATS" -r ntta-status@guavus.com Mohit.Gupta@guavus.com gaurav.babbar@guavus.com mudit.kumar@guavus.com Kevin.Keschinger@guavus.com Kuldeep.Jain@guavus.com Saikat.Prabhakar@guavus.com Girish.Parashar@guavus.com Sameer.Bansal@guavus.com Manish.Sharma@guavus.com Deepak.Verma@guavus.com Mithlesh.Kaushik@guavus.com
	
#	cat  ${log}log.txt | /bin/mail -s "NTT BR COLLECTOR STATS" -r ntta-status@guavus.com gaurav.babbar@guavus.com mudit.kumar@guavus.com
fi
