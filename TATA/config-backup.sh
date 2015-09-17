#for i in `cat nodes | awk '{print $1}'`
#do
#echo -n "Taking Config Backup of Node $i: "
#h=`ssh -q root@$i "hostname"`
#ssh -q root@$i "/opt/tms/bin/cli -t 'en' 'conf t' 'show run full'" > /data/backup/config/`date +%Y`/`date +%m`/`date +%d`/$h.cfg
#echo "Done"
#done

for i in `cat sn-nodes | awk '{print $1}'`
do
echo -n "Taking Config Backup of Node $i: "
expect << EOF
spawn ssh -q root@$i
expect "Password:"
send "Guavus12#\r"
expect "#"
send "hostname\r"
#h=`ssh -q root@$i "hostname"`
#ssh -q root@$i "/opt/tms/bin/cli -t 'en' 'conf t' 'show run full'" > /data/backup/config/`date +%Y`/`date +%m`/`date +%d`/$h.cfg
EOF
echo "Done"
done
