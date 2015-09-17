#!/bin/bash
cmdfile=$1
host=$2
port=$3
script_name=$0

#********************************** usage() *********************************************
usage()
{
   echo  "Mandatory Parameters not set. Processing aborted  "
   echo  "Arguments should be more than four "
   echo  "Usage : $script_name <command file> <hostname/ip>" 
   exit
}
#********************************** END usage() *********************************************


if [ $# -lt 2 ]
then
	usage
fi


while read line
do
var=`echo $line|sed 's/\s//g'`
expect << EOF > /data/scripts/${port}_output_$var.txt
#expect << EOF
spawn telnet $host $port
expect "Password:"
send "Gur9a0n\n"
expect "*>"
send "en\n"
#expect "Password:"
#send "Gur9a0n\n"
#send "terminal length 0\n"
send "terminal length 0\n"
send "$line\n"
send "exit\n"
expect << EOF >> /data/scripts/${port}_output_$var.txt
#expect << EOF
EOF
done < $cmdfile 
#done

sed -i 's/\r//g' /data/scripts/${port}*
