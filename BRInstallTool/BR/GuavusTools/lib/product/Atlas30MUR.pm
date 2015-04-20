package Atlas30MUR;
use lib "./";
# $build=Atlas;
# $version=3.0;

# Provide in a hash reference of ntp details.
sub ntp {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	push(@cmds,"no ntp disable","ssh client global host-key-check no");
	foreach my $server (keys %$prop) {
		push (@cmds, "ntp server $$prop{$server}{ip}");
		if ($$prop{$server}{enable} eq 'yes') {	
			push(@cmds,"no ntp server $$prop{$server}{ip} disable",
				   "ntpdate $$prop{$server}{ip}");
		} else {
		   	push(@cmds,"ntp server $$prop{$server}{ip} disable");
		}
	}

	chomp @cmds;
	return @cmds;

}


# Provide in a hash reference of interfaces and their properties.
sub interface {

	my $self=shift;	
	my $int_hash=shift;
	my @cmds=();
	my @cmd=();
	foreach my $intname(keys %$int_hash) {
		my ($ip, $netmask, $comment, $composed);
		$ip=$$int_hash{$intname}{ip};
		$netmask=$$int_hash{$intname}{subnet};
		#$bonded=$$int_hash{$intname}{bonded}; # Modified
		$comment=undef;
		$comment=$$int_hash{$intname}{comment} if(defined $$int_hash{$intname}{comment});
		$composed=undef;
		$composed=$$int_hash{$intname}{bond} if(defined $$int_hash{$intname}{bond});

		if ($composed=~/\w+/g) {
			$composed=~s/\s//;
			my @count=split /,/,$composed;
			push(@cmd,"bond $intname");
			foreach my $interface (@count) {
			   	my $command="interface $interface bond $intname";
				push (@cmd,"$command",
					   "no interface $interface shutdown",
					   "no interface $interface dhcp");
			}

			push (@cmd,"interface $intname ip address $ip $netmask",
				   "no interface $intname shutdown",
				   "no interface $intname dhcp");
		
		} else {

			push(@cmd,"interface $intname ip address $ip $netmask",
				  "no interface $intname shutdown",
				  "no interface $intname dhcp");
		}
		if (defined $comment) {
			push(@cmd,"interface $intname comment \"$comment\"");

		}

	}
	push (@cmds,@cmd);
	chomp @cmds;
	return @cmds;

}


# Provide in a hash reference of ip-mappings

#sub map {
#	my $self=shift;
#       my $prop=shift;
#       my @cmds=();
#       #my $hosts=$$prop{host};
#       foreach my $host (keys %$prop) {
#               push(@cmds,"ip host $host $$prop{$host}");
#       }
#
#       chomp @cmds;
#       return @cmds;
#}

# Provide in a hash reference of ip gateway and hostnames
sub ip {
	my $self=shift;
	my $prop=shift;
	my @cmds=();
	my $enable=$$prop{'map-hostname'};
	my $hosts=$$prop{host};
	if ($enable eq 'yes') {
		push(@cmds,"ip map-hostname");
	} elsif ($enable eq 'no') {
		push(@cmds,"no ip map-hostname");
	}
	foreach my $host (keys %$hosts) {
		push(@cmds,"ip host $host $$hosts{$host}");
	}
	push (@cmds,"no virt enable");
	my $cmd="banner login \"WARNING NOTICE This system is for the use of authorized users only. Individuals using this system without authority, or in excess of their authority, are subject to having all of their activities on this system monitored and recorded by system personnel. In the course of monitoring individuals improperly using this system, or in the course of system maintenance, the activities of authorized users may also be monitored. Anyone using this system expressly consents to such monitoring and is advised that if such monitoring reveals possible evidence of criminal activity, system personnel may provide the evidence of such monitoring to law enforcement officials.\"";

	my $filter=$$prop{filter}{input}{accept};
	foreach my $source (keys %$filter) {

		push (@cmds, "ip filter chain INPUT rule append tail target ACCEPT protocol udp dest-port 5353 source-addr $$filter{$source} /32");
	}

	push(@cmds,"hostname $$prop{hostname}",
			   #"ip name-server $$prop{'name-server'}",
			   #"ip default-gateway $$prop{'default-gateway'}",
			   "no web enable",
			   "no web http enable",
			   "$cmd",
			"ip filter chain INPUT policy ACCEPT",
			"ip filter enable",
			"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50030",
			"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50070",
			"ip filter chain INPUT rule append tail target DROP protocol udp dest-port 5353",
			"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 13",
			"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 14",
			"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 17",
			"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 18",
			"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 13",
			"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 14",
			"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 17",
			"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 18",
			"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
			"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
			"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
			"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
			"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
			"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
			"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",
			"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0"
		);
	chomp @cmds;
	return @cmds;	
	
}



# Provide in a hash reference of the users and their properties.
sub user {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	my @cmd=();
	foreach my $user (keys %$prop) {
		my $password="";
		$password=$$prop{$user}{password} if($$prop{$user}{password});
		my $status=$$prop{$user}{status};
		my $capability=undef;
		$capability=$$prop{$user}{capability};
		if ($status eq 'disable') {
			@cmd=("username $user disable");
		} else {
			@cmd=(	"no username $user disable",
				"username $user password $password",
			     );
		}
		if (defined $capability) {
			push(@cmd,"username $user capability $capability");
		}
		push(@cmds,@cmd);
	}
	
	chomp @cmds;
	return @cmds;
} 


# Provide in the collector properties hash reference

sub collector {
	my $self=shift;
        my $prop=shift;
        my @cmds=();
	my $count=0;
	
	my $instance=$$prop{instance};
	#foreach my $instanceID (keys %$instance) {
	#	$count=$count+1;
	#}
	foreach my $instanceID (keys %$instance){
		@cmds=("collector add-instance 1");
		my $adaptor=$$instance{$instanceID};
		my $intfce="";
	foreach my $type (keys %$adaptor) {
		my $UC=uc($type);
		$intfce = "httpFile" if $UC=~/http/i;
		$intfce = "flowFile" if $UC=~/flow/i;
        	push (@cmds,"collector modify-instance 1 add-adaptor $type",
		"collector modify-instance 1 modify-adaptor $type add-file-if $intfce",
		"collector modify-instance 1 modify-adaptor $type backup-file-system hostname 127.0.0.1",
   		"collector modify-instance 1 modify-adaptor $type backup-file-system port 9000",
		"collector modify-instance 1 modify-adaptor $type backup-file-system user admin",
   		"collector modify-instance 1 modify-adaptor $type bin-size 300",
   		"collector modify-instance 1 modify-adaptor $type file-format binary",
   		"collector modify-instance 1 modify-adaptor $type file-system hdfs-seq-file",
		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce adapter-profile \"\"",
		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce compression $$adaptor{$type}{$intfce}{compression}",
		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce file-format ascii",
		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce filename-format $$adaptor{$type}{filenameFormat}",
		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce input-directory $$adaptor{$type}{inputdir}",
		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce sync-wait-period 60",
   		"collector modify-instance 1 modify-adaptor $type modify-file-if $intfce transfer-filename-fmt $$adaptor{$type}{transferFilenameFormat}",
   		"collector modify-instance 1 modify-adaptor $type num-bins 2",
   		"collector modify-instance 1 modify-adaptor $type num-objects 100000",
   		"collector modify-instance 1 modify-adaptor $type output-directory /data/collector/$instanceID/output/$type/%y/%m/%d/%h/%mi/$$prop{DCName}.$UC.",
   		"collector modify-instance 1 modify-adaptor $type stack-log-level 0",
		"collector modify-instance 1 modify-adaptor $type timeout $$adaptor{$type}{timeout}",
		"collector modify-instance 1 modify-adaptor $type drop-alarm-clear-interval $$adaptor{$type}{dropAlarmClearInterval}",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-raise-interval $$adaptor{$type}{dropAlarmRaiseInterval}",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-threshold $$adaptor{$type}{dropAlarmThreshold}",
   		"collector modify-instance 1 modify-adaptor $type no-data-alarm-repeat $$adaptor{$type}{noDataAlarmRepeat}"
		);
	}

	}	
                push(@cmds,
			#"collector modify-instance 1 modify-adaptor edrflow modify-file-if flowFile filename-format edrFlow_*_%Mmm_%DD_%hh_%mm_%ss_%YYYY.csv",
			#"collector modify-instance 1 modify-adaptor edrhttp modify-file-if httpFile filename-format edrHTTP_*_%Mmm_%DD_%hh_%mm_%ss_%YYYY.csv",
			#"pm liveness grace-period 600",
			"internal set modify \- /pm/process/collector/term_action value name  /nr/collector/actions/terminate",
   			"pm process collector launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib",
			"pm process collector launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar:/opt/tms/java/MemSerializer.jar",
   			"pm process collector launch auto",
   			"pm process collector launch enable",
   			"pm process collector launch relaunch auto"
                );

                chomp @cmds;
                return @cmds;

}


# Provide in the reference of a hash of cluster properties.
sub cluster {
	my $self=shift;
	my $prop=shift;
	my @cmds=();
	foreach my $id (keys %$prop) {
	@cmds=(
		"cluster id $id",
		"cluster name $$prop{$id}{name}",
		"cluster interface $$prop{$id}{interface}",
		"cluster expected-nodes $$prop{$id}{'expected-nodes'}",
		"cluster master address vip $$prop{$id}{master}{address} $$prop{$id}{master}{subnet}",
		"cluster master interface $$prop{$id}{master}{interface}",
		"cluster enable"
	      );
	}
	
	chomp @cmds;
	return @cmds;
}

# Provide in the reference of a hash of hadoop elements.
sub hadoop {

	my $self=shift;
	my $prop=shift;
	my @cmds=();

	@cmds=(
		"pmx register backup_hdfs",
		"pmx register hadoop",
		"pmx register drbd",
		"pmx register oozie",
		# Configure HDFS Settings
		"pmx set backup_hdfs namenode UNINIT"
	);

	my $clients=$$prop{clients};
	foreach my $client (keys %$clients) {
		# Add the ICN IP Address of each Collector node as a client to the HDFS service
		my $cmd="pmx set hadoop client $$clients{$client}";
		push(@cmds,$cmd);
	}

	my $slaves=$$prop{slaves};
	foreach my $slave (keys %$slaves) {
		# Add the ICN IP Address of each Compute node as a Hadoop Slave
		my $cmd="pmx set hadoop slave $$slaves{$slave}";
		push(@cmds,$cmd);
	}

	# Configure Hadoop Master to utilize the Hadoop Name node Cluster VIP
	push(@cmds,"pmx set hadoop master $$prop{master}{ip}",
		   "pmx set hadoop namenode UNINIT",
		   "pmx set hadoop oozieServer $$prop{master}{ip}"
		   );
	chomp @cmds;
	return @cmds;

}

sub drbd {
	my $self=shift;
	my $prop=shift;
	my @cmds=();

	# Configure DRDB
	#@cmds=("pmx");
	# Hostname and ICN IP address of first name node
	foreach my $host (keys %$prop) {
		if ($host eq 'self') {
			push(@cmds,"pmx set drbd selfip $$prop{self}{ip}");
		} else {
			push(@cmds, "pmx set drbd $host $$prop{$host}{hostname}",
				  , "pmx set drbd $host"."ip $$prop{$host}{ip}");
		}
	}


	# DRBD wait time
	push (@cmds,"pmx set drbd waittime 300");
	#push (@cmds,"quit");

	chomp @cmds;
	return @cmds;
}


# Provide in the reference of hash for SM section.
sub sm {
	my $self=shift;
	my $prop=shift;
	my @cmds=();

	# Configure Storage on both Name Nodes
	@cmds=(	"sm service create PS::BLOCKING:1",
		"sm service modify PS::BLOCKING:1 service-info ps-server-1",
		"sm service-info create ps-server-1",
		"sm service-info modify ps-server-1 host $$prop{instaNode}{ip}",
		"sm service-info modify ps-server-1 port 11111",
		"sm service-info modify ps-server-1 service-type TCP_SOCKET"
		);
	
	chomp @cmds;
	return @cmds;

}

# Provide in the SNMP server properties hash reference
sub snmp {

	my $self=shift;
	my $prop=shift;
	my @cmds=();

	@cmds=(
		"snmp-server enable",
		"snmp-server enable communities",
		"snmp-server community $$prop{server}{community} ro",
		"snmp-server enable traps",
		"snmp-server host $$prop{server}{ip} traps version 2c $$prop{server}{community}",
		"snmp-server listen enable",
		"snmp-server location $$prop{server}{location}",
		"snmp-server traps community $$prop{server}{community}",
		"snmp-server traps event cpu-util-high",
		"snmp-server traps event cpu-util-ok",
		"snmp-server traps event disk-io-high",
		"snmp-server traps event disk-io-ok",
		"snmp-server traps event disk-space-low",
		"snmp-server traps event disk-space-ok",
		"snmp-server traps event interface-down",
		"snmp-server traps event interface-up",
		"snmp-server traps event liveness-failure",
		"snmp-server traps event HDFS-namenode-status",
		"snmp-server traps event no-collector-data",
		"snmp-server traps event collector-data-resume",
		"snmp-server traps event collector-dropped-flow-alarm-cleared",
		"snmp-server traps event collector-dropped-flow-thres-crossed",
		"snmp-server traps event memusage-high",
		"snmp-server traps event memusage-ok",
		"snmp-server traps event netusage-high",
		"snmp-server traps event netusage-ok",
		"snmp-server traps event paging-high",
		"snmp-server traps event paging-ok",
		"snmp-server traps event process-crash",
		"snmp-server traps event process-relaunched",
		"snmp-server traps event test-trap",
		"snmp-server traps event unexpected-shutdown",
		"stats alarm disk_io enable",
		"stats alarm intf_util enable",
		"stats alarm memory_pct_used enable",
		"no snmp-server traps event cmc-status-failure",
   		"no snmp-server traps event cmc-status-ok",
   		"no snmp-server traps event drbd-setprimary-failed",
   		"no snmp-server traps event process-exit",
   		"stats alarm disk_io rising error-threshold 81920",
   		"stats alarm disk_io rising clear-threshold 51200",
   		"stats alarm intf_util rising error-threshold 1572864000",
   		"stats alarm intf_util rising clear-threshold 1258291200",
   		"internal set modify - /stats/config/alarm/cpu_util_indiv/trigger/node_pattern value name /system/cpu/all/busy_pct",
		"pm process statsd restart"
	);
	
	chomp @cmds;
	return @cmds;
}



# Provide reference of a hash for Oozie section properties
sub oozie {
        my $self=shift;
        my $prop=shift;
        my @cmds=();
        push (@cmds,	"pmx set oozie namenode $$prop{namenode}{hostname}",
			"pmx set oozie oozieServer $$prop{namenode}{vip}",
			"pmx set oozie sshHost 127.0.0.1",
			"pmx set oozie snapshotPath /data/snapshots");
	my $jobs=$$prop{job};
	my $count=$$prop{collector}{component}{count};
	foreach my $job(keys %$jobs) {
		push (@cmds, "pmx subshell oozie add job $job $$jobs{$job}{name} $$jobs{$job}{path}");
		my $attributes=$$jobs{$job}{attribute};
			foreach my $attribute (keys %$attributes) {
				push (@cmds, "pmx subshell oozie set job $job attribute $attribute $$attributes{$attribute}");
				
			}
		my $actions=$$jobs{$job}{action};
			foreach my $action (keys %$actions) {
				next if($action=~/ExporterAction/ && $job=~/CubeExporter/);
				push (@cmds, "pmx subshell oozie set job $job action $action attribute timeout $$actions{$action}{attribute}{timeout}");
			}
		push (@cmds, "pmx subshell oozie set job $job attribute jobEnd 2099-12-31T00:00Z");
	}

	my $c=1;
	while ($c<=$count) {
		push (@cmds, "pmx subshell oozie set job EDR action BaseCubes attribute inputDatasets atlas_edrflow_$c",
                     "pmx subshell oozie set job EDR action BaseCubes attribute inputDatasets atlas_edrhttp_$c",

		   # "pmx subshell oozie set job TopUrl action HHUrl attribute inputDatasets atlas_edrhttp_$c",

			"pmx subshell oozie add dataset atlas_edrhttp_$c",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute startOffset 12",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute frequency 5",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute endOffset 1",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute path /data/collector/$c/output/edrhttp/%Y/%M/%D/%H/%mi",
#                       "pmx subshell oozie set dataset atlas_edrhttp_$c attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_edrhttp_$c attribute pathType hdfs", 
			
			"pmx subshell oozie add dataset atlas_edrflow_$c",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute startOffset 12",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute frequency 5",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute endOffset 1",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute path /data/collector/$c/output/edrflow/%Y/%M/%D/%H/%mi",
#                       "pmx subshell oozie set dataset atlas_edrflow_$c attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_edrflow_$c attribute pathType hdfs",
	
		

		     "pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_edrhttp_$c",
		     "pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_edrflow_$c",
	);

		$c=$c+1;
		
	}
	
	push (@cmds,	
			"pmx subshell oozie set job EDR action BaseCubes attribute outputDataset atlas_basecube",
                        "pmx subshell oozie set job EDR action BaseCubes attribute binaryInput true",
                        "pmx subshell oozie set job EDR action BaseCubes attribute mainClass com.guavus.mapred.atlas.job.EdrJob.EdrCubes",
                        #"pmx subshell oozie set job EDR action BaseCubes attribute inputDatasets atlas_edrflow",
                        #"pmx subshell oozie set job EDR action BaseCubes attribute inputDatasets atlas_edrhttp",
                        #"pmx subshell oozie set job EDR action BaseCubes attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job EDR action BaseCubes attribute configFile /opt/etc/oozie/AtlasCubes/BaseCubes.xml",
                        "pmx subshell oozie set job EDR action SubcrBytesAgg attribute outputDataset atlas_subbytes",
                        "pmx subshell oozie set job EDR action SubcrBytesAgg attribute inputDatasets atlas_basecube",
                        "pmx subshell oozie set job EDR action SubcrBytesAgg attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator",
                        #"pmx subshell oozie set job EDR action SubcrBytesAgg attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job EDR action SubcrBytesAgg attribute snapshotDatasets atlas_subbytes",
                        "pmx subshell oozie set job EDR action SubcrBytesAgg attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
                        "pmx subshell oozie set job EDR action TopN attribute outputDataset atlas_topn",
                        "pmx subshell oozie set job EDR action TopN attribute mainClass com.guavus.mapred.atlas.job.TopNJob.TopN",
                        "pmx subshell oozie set job EDR action TopN attribute topNHApp 20",
                        "pmx subshell oozie set job EDR action TopN attribute inputDatasets atlas_basecube",
                        "pmx subshell oozie set job EDR action TopN attribute topApp 20",
                        "pmx subshell oozie set job EDR action TopN attribute topSP 20",
			"pmx subshell oozie set job EDR action TopN attribute topUrlBins 20",
                        #"pmx subshell oozie set job EDR action TopN attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job EDR action TopN attribute configFile /opt/etc/oozie/AtlasCubes/TopN.xml",
                        "pmx subshell oozie set job EDR action SubcrDev attribute outputDataset atlas_subdev",
                        "pmx subshell oozie set job EDR action SubcrDev attribute inputDatasets atlas_basecube",
                        "pmx subshell oozie set job EDR action SubcrDev attribute mainClass com.guavus.mapred.atlas.job.subdevmapib.SubDevMapIBCreator",
                        #"pmx subshell oozie set job EDR action SubcrDev attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job EDR action SubcrDev attribute snapshotDatasets atlas_subdev",
                        "pmx subshell oozie set job EDR action SubcrDev attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
                        "pmx subshell oozie set job EDR action Rollup attribute outputDataset atlas_rollup",
                        "pmx subshell oozie set job EDR action Rollup attribute inputDatasets atlas_basecube",
                        "pmx subshell oozie set job EDR action Rollup attribute mainClass com.guavus.mapred.atlas.job.rollup.Main",
                        "pmx subshell oozie set job EDR action Rollup attribute topnDataset atlas_topn",
                        #"pmx subshell oozie set job EDR action Rollup attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job EDR action Rollup attribute configFile /opt/etc/oozie/AtlasCubes/Rollup.json",

			"pmx subshell oozie set job CubeExporter action ExporterAction attribute binInterval 3600",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute srcDatasets atlas_rollup",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute instaPort 11111",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute minTimeout -1",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute solutionName atlas",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute instaHost $$prop{job}{CubeExporter}{action}{ExporterAction}{attribute}{instaHost}",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute maxTimeout -1",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute fileType Seq",
                        "pmx subshell oozie set job CubeExporter action ExporterAction attribute retrySleep 300",

			"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute outputDataset MonthlyBytes",
                        #"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute timeout -1",
                        #"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute jarFile /opt/tms/java/CubeCreator-atlas2.1.jar",
                        "pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator",
                        "pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute configFile /opt/etc/oozie/SubscriberBytes/config.xml",
                        "pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute inputDatasets BytesAgg_month",
                        "pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute destDataset MonthlyBytes1",
                        "pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute destNamenode $$prop{job}{SubscriberBytes}{action}{DistcpBytes}{attribute}{destNamenode}",
                        "pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute retryCount 1",
                        #"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute timeout 0",
                        "pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute srcNamenode $$prop{job}{SubscriberBytes}{action}{DistcpBytes}{attribute}{srcNamenode}",
                        "pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute srcDataset MonthlyBytes",
                        "pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute retrySleep 10",



			"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute outputDataset SubscriberSegment
",
                        #"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute mainClass com.guavus.mapred.atlas.job.SubscriberSegment.SubscriberSegment",
                        "pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute configFile /opt/etc/oozie/SubscriberSegment/config.xml",
                        "pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute inputDatasets MonthlyBytes1",
                        "pmx subshell oozie set job SubscriberSegment action PushIB attribute ibName subseg.id.map",
                        "pmx subshell oozie set job SubscriberSegment action PushIB attribute srcDataset SubscriberSegmentMPH",
			"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute outputDataset SubscriberSegmentMPH",
			"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute inputDataset SubscriberSegment",
			"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute mainClass com.guavus.mapred.atlas.job.SubscriberSegmentMPH.SubscriberSegmentMPH",

			
			
                      #"pmx subshell oozie set job TopUrl action HHUrl attribute outputDataset atlas_hhurl",
                      #"pmx subshell oozie set job TopUrl action HHUrl attribute mainClass com.guavus.mapred.atlas.job.TopUrlJob.Main",
                      #"pmx subshell oozie set job TopUrl action HHUrl attribute inputDatasets atlas_edrhttp",
                      #"pmx subshell oozie set job TopUrl action HHUrl attribute topnDataset atlas_topn",
                      #"pmx subshell oozie set job TopUrl action HHUrl attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                      #"pmx subshell oozie set job TopUrl action HHUrl attribute configFile /opt/etc/oozie/TopUrl/HHUrl.json",
                      #"pmx subshell oozie set job TopUrl action TopHHUrl attribute outputDataset atlas_topurl",
                      #"pmx subshell oozie set job TopUrl action TopHHUrl attribute inputDatasets atlas_hhurl",
                      #"pmx subshell oozie set job TopUrl action TopHHUrl attribute topUrlBins 10",
                      #"pmx subshell oozie set job TopUrl action TopHHUrl attribute mainClass com.guavus.mapred.atlas.job.TopNUrl.Main",
                      #"pmx subshell oozie set job TopUrl action TopHHUrl attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                      #"pmx subshell oozie set job TopUrl action TopHHUrl attribute configFile /opt/etc/oozie/TopUrl/TopHHUrl.json",
			


			"pmx subshell oozie set job TopSubcr action BytesAgg attribute outputDataset  WeeklyBytes",
                        #"pmx subshell oozie set job TopSubcr action BytesAgg attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job TopSubcr action BytesAgg attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator",
                        "pmx subshell oozie set job TopSubcr action BytesAgg attribute configFile /opt/etc/oozie/TopSubcr/config.xml",
                        "pmx subshell oozie set job TopSubcr action BytesAgg attribute inputDatasets BytesAgg",
                        "pmx subshell oozie set job TopSubcr action TopSubscribers attribute outputDataset TopSubcrWeekly",
                        #"pmx subshell oozie set job TopSubcr action TopSubscribers attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job TopSubcr action TopSubscribers attribute inputDatasets WeeklyBytes",
                        "pmx subshell oozie set job TopSubcr action TopSubscribers attribute topSubcrFlows 1000",
                        #"pmx subshell oozie set job TopSubcr action TopSubscribers attribute topSubcrBytesFlows 2000",
                        "pmx subshell oozie set job TopSubcr action TopSubscribers attribute mainClass com.guavus.mapred.atlas.job.TopSubscriber.TopSubscriber",
                        "pmx subshell oozie set job TopSubcr action TopSubscribers attribute configFile /opt/etc/oozie/TopSubcr/TopSubscribers.xml",
                        "pmx subshell oozie set job TopSubcr action TopSubscribers attribute topSubcrBytes 1000",
                        "pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute outputDataset TopSubcrMerge",
                        #"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
			"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute mainClass com.guavus.mapred.atlas.job.TopSubscriberMerge.TopSubscriberMerge",
                        "pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute configFile /opt/etc/oozie/TopSubcr/config.xml",
                        "pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute inputDatasets TopSubcrWeekly",



			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute outputDataset ConsistentSubcr",
                        #"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute jarFile /opt/tms/java/AtlasCubeCreator-atlas2.0.jar",
                        "pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute inputDatasets TopSubcrMerge",
                        "pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute topSubcrFlows  1000",
                        "pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute topSubcrBytesFlows 2000",
                        "pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute mainClass com.guavus.mapred.atlas.job.ConsistentTopSubscriber.ConsistentTopSubscriber",
                        "pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute configFile /opt/etc/oozie/ConsistentTopSubcr/ConsistentSubcrs.xml",
                        "pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute topSubcrBytes 1000",
                        "pmx subshell oozie set job ConsistentTopSubcr action CopyIB attribute srcDataset  ConsistentSubcr",



			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupOffset 24",
                        #"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_edrhttp",
                        #"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_edrflow",	


			 "pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute cleanupOffset 7",

			
			
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupOffset 1",
                        "pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_basecube",
                        "pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_subdev",
                        "pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_rollup",
                      # "pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_hhurl",
                      # "pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_topurl",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_topn"

		);

# DATASETS

	push (@cmds,
			#"pmx subshell oozie add dataset atlas_edrflow",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute startOffset 12",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute frequency 5",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute endOffset 1",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute doneFile _DONE",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute outputOffset 0",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute path /data/collector/1/output/edrflow/%Y/%M/%D/%H/%mi",
#                       "pmx subshell oozie set dataset atlas_edrflow attribute startTime <dataStart time>",
                        #"pmx subshell oozie set dataset atlas_edrflow attribute pathType hdfs",


			#"pmx subshell oozie add dataset atlas_edrhttp",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute startOffset 12",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute frequency 5",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute endOffset 1",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute doneFile _DONE",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute outputOffset 0",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute path /data/collector/1/output/edrhttp/%Y/%M/%D/%H/%mi",
#                       "pmx subshell oozie set dataset atlas_edrhttp attribute startTime <dataStart time>",
                        #"pmx subshell oozie set dataset atlas_edrhttp attribute pathType hdfs",	


			"pmx subshell oozie add dataset atlas_basecube",
                        "pmx subshell oozie set dataset atlas_basecube attribute startOffset 0",
                        "pmx subshell oozie set dataset atlas_basecube attribute frequency 60",
                        "pmx subshell oozie set dataset atlas_basecube attribute endOffset 0",
                        "pmx subshell oozie set dataset atlas_basecube attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_basecube attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_basecube attribute path /data/output/AtlasBaseCubes/%Y/%M/%D/%H",
#                       "pmx subshell oozie set dataset atlas_basecube attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_basecube attribute pathType hdfs",


			"pmx subshell oozie add dataset atlas_topn",
                        "pmx subshell oozie set dataset atlas_topn attribute startOffset 0",
                        "pmx subshell oozie set dataset atlas_topn attribute frequency 60",
                        "pmx subshell oozie set dataset atlas_topn attribute endOffset 0",
                        "pmx subshell oozie set dataset atlas_topn attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_topn attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_topn attribute path /data/output/TopN/%Y/%M/%D/%H",
#                       "pmx subshell oozie set dataset atlas_topn attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_topn attribute pathType hdfs",


			"pmx subshell oozie add dataset atlas_subbytes",
                        "pmx subshell oozie set dataset atlas_subbytes attribute startOffset 1",
                        "pmx subshell oozie set dataset atlas_subbytes attribute frequency 60",
                        "pmx subshell oozie set dataset atlas_subbytes attribute endOffset 1",
                        "pmx subshell oozie set dataset atlas_subbytes attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_subbytes attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_subbytes attribute path /data/output/AtlasSubcrBytes/%Y/%M/%D/%H",
#                       "pmx subshell oozie set dataset atlas_subbytes attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_subbytes attribute pathType hdfs",


			"pmx subshell oozie add dataset atlas_subdev",
                        "pmx subshell oozie set dataset atlas_subdev attribute startOffset 1",
                        "pmx subshell oozie set dataset atlas_subdev attribute frequency 60",
                        "pmx subshell oozie set dataset atlas_subdev attribute endOffset 1",
                        "pmx subshell oozie set dataset atlas_subdev attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_subdev attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_subdev attribute path /data/output/AtlasSubDevs/%Y/%M/%D/%H",
#                       "pmx subshell oozie set dataset atlas_subdev attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_subdev attribute pathType hdfs",


			"pmx subshell oozie add dataset atlas_rollup",
                        "pmx subshell oozie set dataset atlas_rollup attribute startOffset 0",
                        "pmx subshell oozie set dataset atlas_rollup attribute frequency 60",
                        "pmx subshell oozie set dataset atlas_rollup attribute endOffset 0",
                        "pmx subshell oozie set dataset atlas_rollup attribute doneFile _DONE",
                        "pmx subshell oozie set dataset atlas_rollup attribute outputOffset 0",
                        "pmx subshell oozie set dataset atlas_rollup attribute path /data/output/AtlasRollupCubes/%Y/%M/%D/%H",
#                       "pmx subshell oozie set dataset atlas_rollup attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset atlas_rollup attribute pathType hdfs",
			

			"pmx subshell oozie add dataset BytesAgg_month",
                        "pmx subshell oozie set dataset BytesAgg_month attribute startOffset 31",
                        "pmx subshell oozie set dataset BytesAgg_month attribute frequency 1440",
                        "pmx subshell oozie set dataset BytesAgg_month attribute endOffset 1",
                        "pmx subshell oozie set dataset BytesAgg_month attribute doneFile _DONE",
                        "pmx subshell oozie set dataset BytesAgg_month attribute outputOffset 0",
                        "pmx subshell oozie set dataset BytesAgg_month attribute path /data/output/AtlasSubcrBytes/%Y/%M/%D/23",
#                       "pmx subshell oozie set dataset BytesAgg_month attribute startTime $$prop{dataset}{BytesAgg_month}{attribute}{startTime}",
                        "pmx subshell oozie set dataset BytesAgg_month attribute pathType hdfs",


                        "pmx subshell oozie add dataset MonthlyBytes",
                        "pmx subshell oozie set dataset MonthlyBytes attribute startOffset 0",
                        "pmx subshell oozie set dataset MonthlyBytes attribute frequency 1",
                        "pmx subshell oozie set dataset MonthlyBytes attribute frequencyUnit month",
                        "pmx subshell oozie set dataset MonthlyBytes attribute endOffset 0",
                        "pmx subshell oozie set dataset MonthlyBytes attribute doneFile _DONE",
                        "pmx subshell oozie set dataset MonthlyBytes attribute outputOffset 0",
                        "pmx subshell oozie set dataset MonthlyBytes attribute path /data/output/MonthlyBytes/%Y/%M",
#			"pmx subshell oozie set dataset MonthlyBytes attribute startTime $$prop{dataset}{MonthlyBytes}{attribute}{startTime}",
                        "pmx subshell oozie set dataset MonthlyBytes attribute pathType hdfs",


                        "pmx subshell oozie add dataset MonthlyBytes1",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute startOffset 0",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute frequency 1",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute frequencyUnit month",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute endOffset 0",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute doneFile _DONE",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute outputOffset 0",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute path /data/output/MonthlyBytes1/%Y/%M",
#			"pmx subshell oozie set dataset MonthlyBytes1 attribute startTime $$prop{dataset}{MonthlyBytes1}{attribute}{startTime}",
                        "pmx subshell oozie set dataset MonthlyBytes1 attribute pathType hdfs",

			

			"pmx subshell oozie add dataset SubscriberSegment",
                        "pmx subshell oozie set dataset SubscriberSegment attribute startOffset 0",
                        "pmx subshell oozie set dataset SubscriberSegment attribute frequency 1",
                        "pmx subshell oozie set dataset SubscriberSegment attribute frequencyUnit month",
                        "pmx subshell oozie set dataset SubscriberSegment attribute endOffset 0",
                        "pmx subshell oozie set dataset SubscriberSegment attribute doneFile _DONE",
                        "pmx subshell oozie set dataset SubscriberSegment attribute outputOffset 0",
                        "pmx subshell oozie set dataset SubscriberSegment attribute path /data/output/Segments/%Y/%M",
#                       "pmx subshell oozie set dataset SubscriberSegment attribute startTime 2012-02-01T00:00Z",
                        "pmx subshell oozie set dataset SubscriberSegment attribute pathType hdfs",



			#"pmx subshell oozie add dataset atlas_hhurl",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute startOffset 0",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute frequency 60",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute endOffset 0",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute doneFile _DONE",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute outputOffset 0",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute path  /data/output/HHUrl/%Y/%M/%D/%H",
#                       #"pmx subshell oozie set dataset atlas_hhurl attribute startTime <dataStart time>",
                        #"pmx subshell oozie set dataset atlas_hhurl attribute pathType hdfs",


			
			#"pmx subshell oozie add dataset atlas_topurl",
                        #"pmx subshell oozie set dataset atlas_topurl attribute startOffset 0",
                        #"pmx subshell oozie set dataset atlas_topurl attribute frequency 60",
                        #"pmx subshell oozie set dataset atlas_topurl attribute endOffset 0",
                        #"pmx subshell oozie set dataset atlas_topurl attribute doneFile _DONE",
                        #"pmx subshell oozie set dataset atlas_topurl attribute outputOffset 0",
                        #"pmx subshell oozie set dataset atlas_topurl attribute path /data/output/TopUrl/%Y/%M/%D/%H",
#                       #"pmx subshell oozie set dataset atlas_topurl attribute startTime <dataStart time>",
                        #"pmx subshell oozie set dataset atlas_topurl attribute pathType hdfs",
                        
			
			"pmx subshell oozie add dataset BytesAgg",
                        "pmx subshell oozie set dataset BytesAgg attribute startOffset 7",
                        "pmx subshell oozie set dataset BytesAgg attribute frequency 1440",
                        "pmx subshell oozie set dataset BytesAgg attribute endOffset 1",
                        "pmx subshell oozie set dataset BytesAgg attribute doneFile _DONE",
                        "pmx subshell oozie set dataset BytesAgg attribute outputOffset 0",
                        "pmx subshell oozie set dataset BytesAgg attribute path  /data/output/AtlasSubcrBytes/%Y/%M/%D/23",
#                       "pmx subshell oozie set dataset BytesAgg attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset BytesAgg attribute pathType hdfs",


			"pmx subshell oozie add dataset WeeklyBytes",
                        "pmx subshell oozie set dataset WeeklyBytes attribute startOffset 0",
                        "pmx subshell oozie set dataset WeeklyBytes attribute frequency 10080",
                        "pmx subshell oozie set dataset WeeklyBytes attribute endOffset 0",
                        "pmx subshell oozie set dataset WeeklyBytes attribute doneFile _DONE",
                        "pmx subshell oozie set dataset WeeklyBytes attribute outputOffset 0",
                        "pmx subshell oozie set dataset WeeklyBytes attribute path  /data/output/BytesAggWeekly/%Y/%M/%D",
#                       "pmx subshell oozie set dataset WeeklyBytes attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset WeeklyBytes attribute pathType hdfs",


			"pmx subshell oozie add dataset TopSubcrWeekly",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute startOffset 0",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute frequency 10080",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute endOffset 0",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute doneFile _DONE",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute outputOffset 0",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute path /data/output/TopSubcribers/%Y/%M/%D",
#                       "pmx subshell oozie set dataset TopSubcrWeekly attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset TopSubcrWeekly attribute pathType hdfs",


                        "pmx subshell oozie add dataset TopSubcrMerge",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute startOffset 2",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute frequency 10080",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute endOffset 0",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute doneFile _DONE",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute outputOffset 0",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute path /data/output/TopSubcrMerge/%Y/%M/%D",
#                       "pmx subshell oozie set dataset TopSubcrMerge attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset TopSubcrMerge attribute pathType hdfs",



			"pmx subshell oozie add dataset ConsistentSubcr",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute startOffset 0",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute frequency 10080",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute endOffset 0",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute doneFile _DONE",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute outputOffset 0",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute path /data/output/ConsistentTopSubcr/%Y/%M/%D",
#                       "pmx subshell oozie set dataset ConsistentSubcr attribute startTime <dataStart time>",
                        "pmx subshell oozie set dataset ConsistentSubcr attribute pathType hdfs",

			"pmx subshell oozie add dataset SubscriberSegmentMPH",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute startOffset 0",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute frequency 1",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute frequencyUnit month",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute endOffset 0",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute doneFile _DONE",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute outputOffset 0",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute path /data/output/SegmentsMPH/%Y/%M",
			"pmx subshell oozie set dataset SubscriberSegmentMPH attribute pathType hdfs"

		);

# ADDITIONAL CHANGES AS REQUESTED BY DIVYA ON 24JULY2012.

	push (@cmds, "pmx subshell oozie set job EDR action BaseCubes attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job EDR action SubcrBytesAgg attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job EDR action TopN attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job EDR action SubcrDev attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job EDR action Rollup attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
	#	"pmx subshell oozie set job TopUrl action HHUrl attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
	#	"pmx subshell oozie set job TopUrl action TopHHUrl attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job TopSubcr action BytesAgg attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job TopSubcr action TopSubscribers attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute jarFile /opt/tms/java/CubeCreator-atlas2.2.jar",
		"pmx subshell oozie set job CubeExporter action ExporterAction attribute aggregationInterval 3600",
		"pmx subshell oozie set job CubeExporter action ExporterAction attribute jarName /opt/tms/java/Exporter-atlas2.2.jar",
		"pmx subshell oozie set job CubeExporter action ExporterAction attribute className com.guavus.exporter.Exporter"
	);


	chomp @cmds;
        return @cmds;
}


sub ssh {

        my $self=shift;
        my $prop=shift;
        my @cmds=("ssh client global host-key-check no");
	$usernames=$$prop{key};
	foreach my $user (keys %$usernames) {
        	push(@cmds,
				"ssh client user $user identity $$prop{key}{$user} generate"
			);
	}
	
	chomp @cmds;
	return @cmds;
	
}



1;

