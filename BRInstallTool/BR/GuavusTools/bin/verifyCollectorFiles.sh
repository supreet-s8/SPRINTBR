#!/bin/bash

DELAY=300

rm -f /tmp/etherXX*
 
echo
echo "Checking Collector Data Output in HDFS for 5 minutes"

DCName=`cli -t "en" "show runn full" | grep "modify-adaptor ipfix output-directory" | awk {'print $NF'} | awk -F '/' {'print $NF'}`

curr=`date +%s -d "-10 min"`
res=`echo "(${curr}/300)*300" | bc `
BINPATH=`date -d @${res} "+%Y/%m/%d/%H/%M/"`

HADOOPCMD="hadoop dfs -lsr "
HADOOPCHK="hadoop dfs -test -e "
COL1PATH="/data/collector/1/output/ipfix"
COL2PATH="/data/collector/2/output/ipfix"
bytes1=0
bytes2=0

$HADOOPCHK $COL1PATH/$BINPATH 2>/dev/null
foundpath1=$?
$HADOOPCHK $COL2PATH/$BINPATH 2>/dev/null
foundpath2=$?

if [[ $foundpath1 -eq "0" && $foundpath2 -eq "0" ]]
then
  echo -n "Waiting..."
  a=1; sp="/-\|"; echo -n ' '
  for j in {1..300} 
  do
    printf "\b${sp:a++%${#sp}:1}"
  sleep 1
  done
  echo 
  {
    set -- $($HADOOPCMD $COL1PATH/$BINPATH | grep $DCName | grep -vi done | grep -vi index |  awk '{ sum+=$5} END {print sum}')
  } 2>/dev/null
  bytes1=$1
  {
    set -- $($HADOOPCMD $COL2PATH/$BINPATH | grep $DCName | grep -vi done | grep -vi index |  awk '{ sum+=$5} END {print sum}')
  } 2>/dev/null
  bytes2=$1
  echo
  if [[ ${bytes1} -gt "0" && ${bytes2} -gt "0" ]] 
  then
    echo "checked"
    echo -e "Collector 1 has \033[1m$bytes1 \033[0m bytes of data in $COL1PATH/$BINPATH" 
    echo -e "Collector 2 has \033[1m$bytes2 \033[0m bytes of data in $COL2PATH/$BINPATH"
  else 
    echo -e "Last bin written to disk was of zero size, check in more detail!"
  fi
else
  echo "Could not find Collector Bins at $COL1PATH/$BINPATH and $COL2PATH/BINPATH!!"
fi

echo
if [[ ${bytes1} -gt "0" && ${bytes2} -gt "0" ]]
then
  echo -e "RESULT: \033[1mOK\033[0m"
else
  echo -e "RESULT: \033[1mFAIL!\033[0m"
fi
