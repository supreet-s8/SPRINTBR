#*****************************************************************************************
#Script:   rapper.sh
#Author:   Gaurav Babbar
#Purpose:  Patching delta
#*****************************************************************************************
script_name=$0
#********************************** usage() *********************************************
usage()
{
   echo  "Mandatory Parameters not set. Processing aborted  "
   echo  "Usage : $script_name config_directry delta_path(absolute path)"
   exit
}
#********************************** END usage() *********************************************

applypatch(){
	
	echo $1
	d=`date +'%Y-%m-%d'`
	cp -R $1 $1_bkp_$d
	if [ $? -ne 0 ]
		then
			echo "problem in taking backup..."
			exit
	fi
	cd $1
	patch -p1 < $2/$3
        #if [ $? -ne 0 ]
         #       then
          #              echo "problem in applying patch..."
           #             exit
        #fi
}

if [ $# -lt 2 ]
	then
		usage
fi

CHECK="md5sumcheck.txt"
DIR=$1
DELTA=$2
cur_date=`date +'%Y-%m-%d'`
file=`ls -tr $DELTA|tail -1`

chk_dir=`echo $DIR|grep config`
if [ $? -ne 0 ]
	then
		echo "wrong config path"
		exit
fi

chk=`echo $file|grep delta`
if [ $? -eq 0 ]
	then
		file_date=`echo $file|cut -d. -f2|cut -d'_' -f1`
else
	echo "wrong delta path"
	exit
fi

#md5sumcheck=`md5sum $DELTA/$file | cut -d' ' -f1`

if [[ "$cur_date" == "$file_date" ]]
	then
		md5sumcheck=`md5sum $DELTA/$file | cut -d' ' -f1`
		if [ -f "$CHECK" ]
			then
				md5sumprev=`cat $CHECK`
				if [[ "$md5sumcheck" == "$md5sumprev" ]]
					then
						echo "you are trying it second time. press y/Y to continue else enter to quit"
						read continue
						if [ "$continue" == "Y" ] || [ "$continue" == "y" ]
							then
								applypatch $DIR $DELTA $file
						else
							echo "exiting...."
							exit
						fi
				else
					echo $md5sumcheck > $CHECK
					applypatch $DIR $DELTA $file
				fi
		else
			echo $md5sumcheck > $CHECK
			applypatch $DIR $DELTA $file
		fi
else
	echo "File present in directory is not of current date.Please check"
	echo "Aborting process"
	exit
fi
