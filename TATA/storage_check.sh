#!/bin/bash

perl /data/scripts/stgStatus.pl -H 10.10.20.139

if [ -s /data/scripts/error.log ]
then
	echo "Storage Not Optimal:" > /data/scripts/temp
	echo "" >> /data/scripts/temp
	cat /data/scripts/error.log >> /data/scripts/temp
	
	cat /data/scripts/temp | /bin/mail -s "TCL-Guavus: Storage Critical" -r tclmonitor@guavus.com  gaurav.babbar@guavus.com Ankur.Gupta@guavus.com noc.support@guavus.com
fi

rm -f /data/scripts/temp	
