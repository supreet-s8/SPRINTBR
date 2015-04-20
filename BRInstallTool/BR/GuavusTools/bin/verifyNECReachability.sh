#!/bin/bash

SAP=`cli -t "en" "internal query get - /tps/process/oozie/jobs/Distcp/actions/DistcpAction/attribute/destNamenode/value" | awk {'print $(NF-1)'}`
NAP=`cli -t "en" "internal query get - /tps/process/oozie/jobs/Distcp/actions/DistcpAction/attribute/destNamenode/value" | awk {'print $(NF-1)'}`
HADOOPCHK="hadoop dfs -test -e "

echo "Checking reachability of SAP HDFS..."
$HADOOPCHK hdfs://${SAP}:9000/data  2>/dev/null
foundpath1=$?

echo "Checking reachability of NAP HDFS..."
$HADOOPCHK hdfs://${NAP}:9000/data  2>/dev/null
foundpath2=$?

if [[ $foundpath1 -eq "0" ]] 
then
  echo -e "SAP HDFS is reachable - \033[1;32mOK\033[0m"
else
  echo -e "WARNING!!! SAP HDFS is not reachable - \033[1;31mERROR\033[0m"
fi

if [[ $foundpath2 -eq "0" ]] 
then
  echo -e "NAP HDFS is reachable - \033[1;32mOK\033[0m"
else
  echo -e "WARNING!!! NAP HDFS is not reachable - \033[1;31mERROR\033[0m"
fi

