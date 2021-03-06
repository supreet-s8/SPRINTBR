#!/usr/bin/perl 

use Carp;
use Getopt::Long;
use Time::Local;

###########################################################################################
# Setup options

#my $node=undef;
my $nextHour=undef;
my $previousHour=undef;
my $resume=undef;
my $help=undef;
my $dataStartTime=undef;
my $execute=undef;
my $output=GetOptions( 
                        #"node:s"                 =>      \$node,
			"nextHour"		 =>	 \$nextHour,
			"previousHour"		 =>	 \$previousHour,
			"resume"		 =>	 \$resume,
                        "setTime:s"         	 =>      \$dataStartTime,
			"execute"		 =>	 \$execute,
                        "help"                   =>      \$help);



#========================#
# CMDS JOBS
#========================#
our %jobLagScheduleMinutes=(
		  Distcp		=> 60,
		  TopSubcr		=> 60*24*7,
		  CleanupAtlas		=> 60,
		  CleanupLogs 		=> 60,
		  CleanupCollector	=> 60,
		  Atlas			=> 60,
		  ConsistentTopSubcr	=> 60*24*21,
		  BackupDistcpNAP	=> 0,
		  TopNcp		=> 60
		  
             );

our %jobLagScheduleMonths=(
				SubscriberBytes	=>      {Months         =>      1,},
                                                #dataSets       =>      ["BytesAgg_month"]},
			        CleanupMonthlyData	=>      {Months         =>      1,},
                                                #dataSets       =>      ["BytesAgg_month"]}
                                 );
#========================#


if ((! $output) or ($help)) {
        &usage;
        exit;
}

sub usage {
        print <<EOF

Usage:

Provide in the following options.


--nextHour                      => No input required with this option. 

--previousHour                  => No input required with this option. 

--resume		   	=> No input required with this option. Option consults done.txt

--execute		   	=> Lets you execute the commands on both Master and Standby Nodes.

--setTime	                => Provide the Data Start Time (Format: 2013-02-28T15:00Z). Respective oozie jobs will get
                                   scheduled taking this as a base time.



EOF

}
#--node		(Mandatory)	=> Provide IP address of the Master/Standby namenode.

####################################### MAIN ################################################

my $cmds=undef;

if(! ($nextHour || $previousHour || $resume || $dataStartTime)){
        &usage();
        exit;

}

if($dataStartTime && ($nextHour || $previousHour || $resume)) {
	&usage();
	exit;
}

if(($nextHour && $previousHour) || ($previousHour && $resume) || ($resume && $nextHour)) {
        &usage();
        exit;
}


#&usage() if (! $node);

#die "\nError: Invalid node IP address.\n\n" if (! is_valid($node));

if($nextHour) {
$dataStartTime=`date -d "1 hour" +%Y-%m-%dT%H:00Z`;

} elsif ($previousHour) {
$dataStartTime=`date -d "1 hour ago" +%Y-%m-%dT%H:00Z`;

} elsif ($resume) {
# Consult done.txt and Execute #

my $cmds=&consult_done();
	if (! ref $cmds){
		print "\nError...!\nCould not stat done.txt for base value of Job: $cmds.\n\n";
		print "Use any of the other options to configure jobStart times.\n\n";
		exit;
	}

print "\nCommands list to be issued on node:\n\n";
print "$_\n" foreach(@$cmds);

	# CALL EXECUTE #
	if ($execute) {
	my $state=execute($cmds,$node);
		if (! $state) {
			die "Can not complete execution...! Error: 911\n\n";
		}
	}
	###

print "\nProcess completed.\n\n";
exit;

} 


# Compute Fresh and Execute #

if($dataStartTime) {
die "Not a valid time format! Please try again.\n" if (! &isValidTime($dataStartTime));

print "\nGenerating Oozie job times...\n";
$cmds=&jobstart_cmds($dataStartTime);

print "\nCommands list to be issued on node:\n\n";
print "$_\n" foreach(@$cmds);

        # CALL EXECUTE #
        if ($execute) {
        my $state=execute($cmds,$node);
                if (! $state) {
                        die "Can not complete execution...! Error: 911\n\n";
                }
        }
        ###

print "\nProcess completed.\n\n";
} else {
	print "Could not stat Data Start Time. Exception!\n Committing Exit...! Error:007!\n";
}





####################################### Subroutines #######################################

sub jobstart_cmds {

        my $dataStartTime=shift;
        my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
        if ($dataStartTime=~(/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
                $dataYY=sprintf("%04d",$1);
                $dataMM=sprintf("%02d",$2);
                $dataDD=sprintf("%02d",$3);
                $datahh=sprintf("%02d",$4);
                $datamm=sprintf("%02d",$5);
        }
        my @cmds=();

        foreach my $job (sort keys %jobLagScheduleMinutes) {
                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");
		#push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set dataset atlas_selfipcleanup attribute startTime $jobSchedule") if ($job=~/^Atlas$/);

        }

        foreach my $job (keys %jobLagScheduleMonths) {
                my $jobDataMM=$dataMM+$jobLagScheduleMonths{$job}{Months};
                my $jobDataYY=$dataYY;
		$jobDataMM=sprintf("%02d",$jobDataMM);
                if ($jobDataMM>12) {
                        $jobDataMM=sprintf("%02d",$jobDataMM-12);
                        #print "jobDataMM=$jobDataMM\n";
                        $jobDataYY=$jobDataYY+1;
                }
                my $jobDataDD="01";
                my $jobDatahh="00";
                my $jobDatamm="00";
                my $jobSchedule="$jobDataYY\-$jobDataMM\-$jobDataDD"."T"."$jobDatahh".":"."$jobDatamm"."Z";
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");
                
                # StartTime for Datasets as input to Monthly jobs need to be set at 00:00Hrs on same day as of other datasets.
                #my $jobLagMonths=$jobLagScheduleMonths{$job}{dataSets};
                #foreach my $dataSet (@$jobLagMonths){
                #        my $dataSethh="00";
                #        my $dataSetmm="00";
                #        my $dataSetStartTime="$dataYY\-$dataMM\-$dataDD"."T"."$dataSethh".":"."$dataSetmm"."Z";
                #        push(@cmds,"pmx subshell oozie set dataset $dataSet attribute startTime $dataSetStartTime");
                #}

        }
	#push (@cmds,"/opt/tms/bin/cli -t \"en\" \"conf t\" \"write memory\"");
        chomp @cmds;
        return \@cmds;

}


sub consult_done {
	my $hadoop=undef;
	my @cmds =();
	$hadoop=`which hadoop`;
	chomp $hadoop;
	print "Can not consult done.txt files for Jobs.\nHadoop not available on this system! Cheating!" if (! defined $hadoop);
	print "Consulting done.txt for all jobs.\n";
	foreach my $job (sort keys %jobLagScheduleMinutes) {
		my $dataStartTime=`$hadoop dfs -cat /data/$job/done.txt 2>/dev/null`;
		chomp $dataStartTime;
		
		#print "Time for Job: $job is $dataStartTime\n";
		return $job if(!defined $dataStartTime);    # Return JOBNAME if any job does not has done.txt 

 		# Return JOBNAME if any job has bad/incomplete or missing time format in done.txt
		return $job if($dataStartTime!~(/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/));

                my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");
		#push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set dataset atlas_selfipcleanup attribute startTime $jobSchedule") if ($job=~/^Atlas$/);

        }

	my $months=undef;

        foreach my $job (sort keys %jobLagScheduleMonths) {
                my $dataStartTime=`$hadoop dfs -cat /data/$job/done.txt 2>/dev/null`;
                chomp $dataStartTime;

                #print "Time for Job: $job is $dataStartTime\n";
                return $job if(!defined $dataStartTime);    # Return JOBNAME if any job does not has done.txt

                # Return JOBNAME if any job has bad/incomplete or missing time format in done.txt
                return $job if($dataStartTime!~(/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/));

		my ($dataYY,$dataMM,$dataDD,$datahh,$datamm);
	        if ($dataStartTime=~(/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/)) {
	                $dataYY=sprintf("%04d",$1);
        	        $dataMM=sprintf("%02d",$2);
                	$dataDD=sprintf("%02d",$3);
               		$datahh=sprintf("%02d",$4);
                	$datamm=sprintf("%02d",$5);
        	}
		
                my $jobDataMM=$dataMM+$jobLagScheduleMonths{$job}{Months};
		$joDataMM=sprintf("%02d",$jobDataMM);
                my $jobDataYY=$dataYY;
                if ($jobDataMM>12) {
                        $jobDataMM=sprintf("%02d",$jobDataMM-12);
                        print "jobDataMM=$jobDataMM\n";
                        $jobDataYY=$jobDataYY+1;
                }
                my $jobDataDD="01";
                my $jobDatahh="00";
                my $jobDatamm="00";
                my $jobSchedule="$jobDataYY\-$jobDataMM\-$jobDataDD"."T"."$jobDatahh".":"."$jobDatamm"."Z";
		
                #my $jobSchedule=_dataStartToJobStart($dataStartTime, $jobLagScheduleMinutes{$job});
                push(@cmds, "/opt/tps/bin/pmx.py subshell oozie set job $job attribute jobStart $jobSchedule");

        }

	#push (@cmds,"/opt/tms/bin/cli -t \"en\" \"conf t\" \"write memory\"");
	chomp @cmds;
	return \@cmds;

}

sub execute {
	my $cmds=shift;
	my $IP=get_ips();
	if (! $IP) {
		print "Committing Exit...!\n";
		exit;
	}
	my $cmd=undef;
	$cmd.="$_\n" foreach(@$cmds);
	chomp $cmd;
	foreach my $ip (@$IP) {
		chomp $ip;
		print "\nExecuting...\t At $ip.\n";
                my $out=`ssh -q root\@$ip "$cmd"`;
                if ($out=~/invalid command/i) {
                        print "\nInvalid command error.\nAborting Process...!\n";
                        print "\nOUTPUT:\n"."x"x50;
			print "\n";
                        print "$out\n";
                        print "x"x50;
                        print "\n\n";
                        return undef;

                }
                return undef if ($? != 0);
		print "\n";
	}
	return 1;
}

sub get_ips {
	my $master=undef;
	my $standby=undef;
	$master=`/opt/tms/bin/cli -t "en" "conf t" "show cluster global brief" | grep master`; 
	chomp $master;
	#3*    master   online    GUA21NSA-A-GV-HP 0.0.0.0         192.168.10.20  
	$master=~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$/;
	$master=$1;
	$standby=`/opt/tms/bin/cli -t "en" "conf t" "show cluster global brief" | grep standby`;
	chomp $standby;
	$standby=~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$/;
	$standby=$1;
	if (!($master && $standby)) {

		print "Error: Can not determine cluster Master and Standby IPs.\n";
		return undef;

	}
	my @ip=();
	push (@ip, $master, $standby);
	return \@ip;

}
######################## Helper Subroutines ########################
sub _dataStartToJobStart {

        my ($dataStartTime, $lagMinutes) = @_;
        $dataStartTime =~ s/Z$//;
        my ($date, $time) = split "T", $dataStartTime;
        my ($yy, $MM, $dd) = split "-", $date;
        my ($hh, $mm) = split ":", $time;
        $MM=$MM-1;     
        $MM=11 && $yy=$yy-1 if $MM<0;
        my $dataStartEpoch = timelocal(0,$mm,$hh,$dd,$MM,$yy);
        my $newEpoch = $dataStartEpoch + $lagMinutes*60;
        my ($wday,$yday,$isdst, $sec);
        my $test=localtime($newEpoch);
        ($sec,$mm,$hh,$dd,$MM,$yy,$wday,$yday,$isdst) = localtime($newEpoch);
        $MM=$MM+1;
        $MM = sprintf("%02d", $MM);
        $dd = sprintf("%02d", $dd);
        $mm = sprintf("%02d", $mm);
        $hh = sprintf("%02d", $hh);
        my $startTime=(1900+$yy)."-".$MM."-".$dd."T".$hh.":".$mm."Z";
        return $startTime;
}

sub isValidTime {
        my $startTime=shift;
        return $startTime if ($startTime=~/^(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/);
        return undef;
}

sub is_valid {
        my $IP=shift;
        chomp $IP;
        $IP=~s/\s+//g;
        return 1 if(($IP=~/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) && ($1<=255) && ($2<=255) && ($3<=255) && ($4<=255));
        return undef;
}

#-------------------------------------------------------------------------------------------------------------------------------

