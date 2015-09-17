#!/bin/bash

for i in `cat ~/nodes`
do
ssh -q $i "hostname"
#ssh -q $i "dmidecode -s system-serial-number"
#ssh -q $i "dmidecode --type system | egrep 'Manufacturer|Product'"
#ssh -q $i "dmidecode -t 17 | grep Size | grep -v 'No Module' | wc -l"
#ssh -q $i "dmidecode -t 17 | grep Size | grep -v 'No Module'"
#ssh -q $i "dmidecode --type processor | grep Version"
#ssh -q $i "ifconfig -a | grep 172.16"
ssh -q $i "fdisk -l"
done
