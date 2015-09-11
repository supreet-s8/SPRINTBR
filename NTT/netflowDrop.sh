#!/bin/bash

LOG="/data/dropNetflow"


if [ -f ${LOG}/tmp ]
then
	rm -f ${LOG}/tmp
fi

out=`ssh -q root@192.168.10.200 "${LOG}/netflowDrop.sh" 2>/dev/null | cut -d. -f1`
count=`ssh -q root@192.168.10.200 "cat ${LOG}/Found_Only_In_ipTCPDump"|wc -l`


#if [[ "$out" > "10" ]]
if [ $out -gt 10 ]
then

	echo "Drop Percentage Of Routers is ${out}% " >> ${LOG}/tmp
	echo >> ${LOG}/tmp
	if [ $count -gt 0 ]
		then

        		echo "Routers Found only in TCP Dump" >> ${LOG}/tmp
			echo "" >> ${LOG}/tmp
        		ssh -q root@192.168.10.200 "cat ${LOG}/Found_Only_In_ipTCPDump" >> ${LOG}/tmp
	fi

fi

if [ -s ${LOG}/tmp ]
then
	cat ${LOG}/tmp | /bin/mail -s "Drop percentage" -r ntta-status@guavus.com gaurav.babbar@guavus.com Ankur.Gupta@guavus.com noc.support@guavus.com Manish.Sharma@guavus.com Prabir.Patra@guavus.com mudit.kumar@guavus.com
fi


