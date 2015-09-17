#!/bin/bash

LOG="/data/dropNetflow"


if [ -f ${LOG}/tmp_202 ]
then
	rm -f ${LOG}/tmp_202
fi

out=`ssh -q root@10.10.10.202 "${LOG}/netFlowDrop.sh" 2>/dev/null | cut -d. -f1`
count=`ssh -q root@10.10.10.202 "cat ${LOG}/Found_Only_In_ipTCPDump"|wc -l`
hname=`ssh -q root@10.10.10.202 "hostname"`
echo "`date` $hname drop % : $out , Routers : $count" >> $LOG/log

if [ $out -gt 10 ]
then
	echo "`date` $hname Drop Percentage Of Routers is ${out}% " >> $LOG/log
	echo "$hname Drop Percentage Of Routers is ${out}% " >> ${LOG}/tmp_202
	echo >> ${LOG}/tmp_202
	if [ $count -gt 0 ]
		then

        		echo "`date` $hname : $count Routers Found only in TCP Dump" >> ${LOG}/log
        		echo "$hname : Routers Found only in TCP Dump" >> ${LOG}/tmp
			echo "" >> ${LOG}/tmp_202
        		ssh -q root@10.10.10.202 "cat ${LOG}/Found_Only_In_ipTCPDump" >> ${LOG}/tmp_202
			
	fi

fi


if [ -s ${LOG}/tmp_202 ]
then
	cat ${LOG}/tmp_202 | /bin/mail -s "Drop percentage $hname" -r tclmonitor@guavus.com  gaurav.babbar@guavus.com Ankur.Gupta@guavus.com noc.support@guavus.com Manish.Sharma@guavus.com Prabir.Patra@guavus.com mudit.kumar@guavus.com Pragati.Dhingra@guavus.com Aditya.Kumar@guavus.com
fi

