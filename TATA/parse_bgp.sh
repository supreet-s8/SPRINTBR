#!/bin/bash


LOG=/data/scripts/

excp=`cat ${LOG}except | tr '\n' '|' |sed 's/|$//g'`

${LOG}new_runcmd.sh ${LOG}command 10.10.10.201 3001
${LOG}new_runcmd.sh ${LOG}command 10.10.10.201 3002
${LOG}new_runcmd.sh ${LOG}command 10.10.10.201 3003


if [ -f ${LOG}log.txt ]
then

	rm -f ${LOG}log.txt
fi

if [ -f ${LOG}error_log.txt ]
then

        rm -f ${LOG}error_log.txt
fi

out=`egrep -v "$excp" ${LOG}300* |grep -i Idle`
#out=`grep -i Idle ${LOG}300*`

if [[ $out ]]
then
 for i in 3001 3002 3003
 do	
	output=`cat ${LOG}/${i}_output_showipbgpsummary.txt|egrep -v "$excp" | grep -i Idle`
	#output=`cat ${LOG}/${i}_output_showipbgpsummary.txt|grep -i Idle`
	if [[ $output ]]
	then
		echo "port : $i" >> ${LOG}log.txt
		echo "$output" >> ${LOG}log.txt
		echo "" >> ${LOG}log.txt
	fi	
 done
fi

 for i in 3001 3002 3003
 do
        error=`cat ${LOG}/${i}_output_showipbgpsummary.txt | grep "Connection refused"`
      #  echo $error
        if [[ $error ]]
        then
                echo "port $i Not reachable" >> ${LOG}error_log.txt
        fi
 done

if [ -f ${LOG}log.txt ]
then

	cat ${LOG}log.txt | mailx -s "Tata-GUAVUS BGP Idle Sessions" -r tclmonitor@guavus.com gaurav.babbar@guavus.com ankur.gupta@guavus.com noc.support@guavus.com GTAC-Systems@tatacommunications.com Pragati.Dhingra@guavus.com
	#cat ${LOG}log.txt | mailx -s "Tata-GUAVUS BGP Idle Sessions" -r tclmonitor@guavus.com gaurav.babbar@guavus.com 
fi

if [ -f ${LOG}error_log.txt ]
then

        cat ${LOG}error_log.txt | mailx -s "Tata-GUAVUS BGP Port Not Reachable" -r tclmonitor@guavus.com gaurav.babbar@guavus.com ankur.gupta@guavus.com noc.support@guavus.com Pragati.Dhingra@guavus.com
        #cat ${LOG}error_log.txt | mailx -s "Tata-GUAVUS BGP Idle Sessions" -r tclmonitor@guavus.com gaurav.babbar@guavus.com
fi
