#!/bin/bash

file=$1

script_name=$0

#********************************** usage() *********************************************
usage()
{
   echo  "Mandatory Parameters not set. Processing aborted  "
   echo  "Arguments should be 1"
   echo  "Usage : $script_name <file>" 
   exit
}
#********************************** END usage() *********************************************

#LOG=/data/scripts/new_sib_approach

if [ $# -lt 1 ]
then
	usage
fi


if [ -f out_del.sh ]
then
	rm -f out_del.sh
fi

perl -pi -e 's/^\/opt\/samples\/ip-solutions-config\/rubix\/entitycli.py/\/opt\/samples\/ip-solutions-config\/rubix\/entitycli.py --UI/g' $file

perl -pi -e 's/--deleterules/-d/g' $file

perl -pi -e 's/--user admin/--user=admin/g' file_del_1.sh $file

perl -pi -e 's/--passwd Admin1234/--passwd=Admin\@123/g' $file

while read line
do
	first=`echo $line | awk '{$NF="";print $0}'`
	last=`echo $line | awk '{print $NF}'|awk -F: 'BEGIN {OFS=":"} {$NF="";print $0}'|sed 's/:$/"/g'`

	echo "${first}${last}" >> out_del.sh
done < $file
