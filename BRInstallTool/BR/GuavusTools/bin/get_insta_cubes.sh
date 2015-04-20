#!/bin/bash

function usage {
  echo -e "Usage: `basename $0` [--start=YYYY-MM-DD] [--end=YYYY-MM-DD] [--days=n]\n"
  exit 0
}
VALID=0
EXPECTED_ARGS=2
if [ $# -ne $EXPECTED_ARGS ]
then
  usage
fi

for arg in $@
do
  option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"` ; value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
  if [ "$value" == "$option" ]; then value=""; fi
  case $option in
  --start ) starttime="$value";;
  --end ) endtime="$value";;
  --days ) days="$value";;
  esac
done

if [[ $starttime && $days ]] ; then
  starttime=`date -d  "$starttime" "+%s"` ; endtime=$(( $starttime + $days*86400 ))
elif [[ $endtime && $days ]] ; then
  endtime=`date -d  "$endtime" "+%s"` ; starttime=$(( $endtime - $days*86400 ))
elif [[ $starttime && $endtime ]] ; then
  starttime=`date -d  "$starttime" "+%s"` ; endtime=`date -d  "$endtime" "+%s"`
  if [[ $starttime > $endtime ]] ; then echo "End is earlier than start!!!" ; usage ; fi
fi


# Get our stuff squared
idbmysql='/usr/local/Calpont/mysql/bin/mysql --defaults-file=/usr/local/Calpont/mysql/my.cnf -u root'
DBNAME=`/opt/tms/bin/cli -t 'en' 'conf t' 'insta show-config' | grep cubes_database | awk -F ":" {'print $NF'}`
MINTS=`${idbmysql} $DBNAME -e "select mints from bin_metatable where aggregationinterval = '-1'" | grep -v mints`
MAXTS=`${idbmysql} $DBNAME -e "select maxts from bin_metatable where aggregationinterval = '-1'" | grep -v maxts`

echo "Fetching data from `date -d @$starttime`  to `date -d @$endtime` "
if [[ $starttime < $MINTS ]] ; then
  echo Data currently available in $DBNAME from  `date -d @$MINTS` and you chose to start from `date -d @$starttime`
  exit 1
elif [[ $endtime > $MAXTS ]] ; then
  echo Data currently available in $DBNAME upto `date -d @$MINTS` and you chose to end at `date -d @$starttime`
  exit 1
fi

echo "Backing up....."
# If we made it so far, then we probably get extract data from insta
backdir=instaback_`date "+%s"`
mkdir -p $backdir
/opt/tms/bin/cli -t "en" "conf term" "insta backup dbname $DBNAME start $starttime end $endtime to /data/${backdir}"
tar czf $backdir.tar.gz /data/$backdir
rm -fr /data/$backdir
echo "done"
