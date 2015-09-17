#!/bin/bash

LOG="/data/dropNetflow"


if [ -f ${LOG}/tmp ]
then
	rm -f ${LOG}/tmp
fi

for i in 201 202
do

	hname=`ssh -q root@10.10.10.${i} "hostname"`
	dt=`ssh -q root@10.10.10.${i} '/opt/tms/bin/cli -t "en" "conf t" "collector stats instance-id 10 adaptor-stats netflow total-flow interval-type 1-hour interval-count 1"' | tail -1|awk '{print $2" "$3}'`
	col_stats_netflow=`ssh -q root@10.10.10.${i} '/opt/tms/bin/cli -t "en" "conf t" "collector stats instance-id 10 adaptor-stats netflow total-flow interval-type 1-hour interval-count 1"' | tail -1|awk '{print $NF}'`
	
	col_stats_v10=`ssh -q root@10.10.10.${i} '/opt/tms/bin/cli -t "en" "conf t" "collector stats instance-id 10 adaptor-stats v10 total-flow interval-type 1-hour interval-count 1"' | tail -1|awk '{print $NF}'`

	echo "`date` $hname Flow date: $dt collector stats netflow: $col_stats_netflow , v10: $col_stats_v10" >> ${LOG}/col_stats	

	if [[ $col_stats_netflow -le 90000000 ]] || [[ $col_stats_v10 -le 25000000 ]]
	then
		echo "Collector Total Flow Below Threshold for host $hname" >> ${LOG}/tmp
		echo "Flow date: $dt netflow: $col_stats_netflow , ipfix: $col_stats_v10" >> ${LOG}/tmp
		echo "" >> ${LOG}/tmp
	fi


done

if [ -s ${LOG}/tmp ]
then
	cat ${LOG}/tmp | /bin/mail -s "Collector Total Flow Drop" -r tclmonitor@guavus.com  gaurav.babbar@guavus.com Ankur.Gupta@guavus.com noc.support@guavus.com Manish.Sharma@guavus.com Prabir.Patra@guavus.com mudit.kumar@guavus.com Pragati.Dhingra@guavus.com Aditya.Kumar@guavus.com
fi
