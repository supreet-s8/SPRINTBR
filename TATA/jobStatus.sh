#!/bin/bash


vip="10.10.10.201"

ssh -q root@$vip "/opt/tms/bin/pmx subshell oozie show workflow RUNNING jobs" > /tmp/job_status

sed -i '/^Job/d' /tmp/job_status
sed -i '/^-/d' /tmp/job_status

job_start_time=`cat /tmp/job_status | awk '{print $8,$9}'`

epoch_job_start_time=`date --date "$job_start_time" +%s`

system_time=`date +%s`

diff_time=`expr $system_time - $epoch_job_start_time`

if [ $diff_time -le 7200 ]
then
	name_of_job=`cat /tmp/job_status | awk '{print $2}'`	
	id_of_job=`cat /tmp/job_status | awk '{print $1}'`
	echo "Job <i><b>$name_of_job ($id_of_job)</b></i> has been running for more than 2 hours. Please investigate/inform concerned person immediately." > /tmp/email_job_status
	(echo "Subject: TCL Job Stuck";echo "From: tcl-alerts@guavus.com";echo "To: ankur.gupta@guavus.com";echo "Content-Type: text/html";cat /tmp/email_job_status) | /usr/lib/sendmail -t
fi
