package Atlas30SU1;
use lib "./";
#use POSIX qw(strftime);
# $build=Atlas;
# $version=3.0;
# Provide in a hash reference of ntp details.
sub ntp {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	push(@cmds,"no ntp disable","clock timezone UTC","ssh client global host-key-check no");
	foreach my $server (keys %$prop) {
		push (@cmds, "ntp server $$prop{$server}{ip}");
		if ($$prop{$server}{enable} eq 'yes') {	
			push(@cmds,"no ntp server $$prop{$server}{ip} disable",
				   "ntpdate $$prop{$server}{ip}");
		} else {
		   	push(@cmds,"ntp server $$prop{$server}{ip} disable");
		}
	}

	push (@cmds, "aaa authentication attempts lockout max-fail 3",
			"aaa authentication attempts lockout unlock-time -1",
			"no virt enable",
			"no pm process insta launch enable",
			"no pm process insta launch relaunch auto",
			"no pm process insta launch auto",
			"no snmp-server traps event insta-adaptor-down",
			"pm process insta terminate"
		);

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
	my $name=undef;
	$name=$$prop{'name-server'};
	if ($name){
	foreach my $n (keys %$name){
		push (@cmds,"ip name-server $$name{$n}") if ($$name{$n});
	}
	}
	#"ip name-server $$prop{'name-server'}",
	#Added for Collective ipfilter rules of 50060/70/76 ports for Collector/Namenodes and Computes (i.e. Hadoop Cluster) #
	my $port=undef;
	$port=$$prop{filter}{port}{accept};

	my $filter=$$prop{filter}{input}{accept};
	push (@cmds, "ip filter chain INPUT rule append tail target ACCEPT dup-delete in-intf lo");
	if ($filter) {
        	foreach my $source (keys %$filter) {

                	push (@cmds, "ip filter chain INPUT rule append tail target ACCEPT protocol udp dest-port 5353 source-addr $$filter{$source} /32",
				     "ip filter chain INPUT rule append tail target ACCEPT dup-delete source-addr $$filter{$source} /32 dest-port 8080 protocol tcp");
        	}

		push (@cmds, "ip filter chain INPUT rule append tail target DROP dup-delete dest-port 8080 protocol tcp");
		
	}
	foreach my $host (keys %$hosts) {
		push(@cmds,"ip host $host $$hosts{$host}");
	}

	my $cmd="banner login \"WARNING NOTICE This system is for the use of authorized users only. Individuals using this system without authority, or in excess of their authority, are subject to having all of their activities on this system monitored and recorded by system personnel. In the course of monitoring individuals improperly using this system, or in the course of system maintenance, the activities of authorized users may also be monitored. Anyone using this system expressly consents to such monitoring and is advised that if such monitoring reveals possible evidence of criminal activity, system personnel may provide the evidence of such monitoring to law enforcement officials.\"";

        #my $filter=$$prop{filter}{input}{accept};
        #foreach my $source (keys %$filter) {

        #       push (@cmds, "ip filter chain INPUT rule append tail target ACCEPT protocol udp dest-port 5353 source-addr $$filter{$source} /32");
        #}

		push(@cmds,"hostname $$prop{hostname}",
			   #"ip default-gateway $$prop{'default-gateway'}",
			   "no web enable",
			   "no web http enable",
			   "$cmd",
			   #"aaa authentication attempts lockout max-fail 3",
                        "ip filter chain INPUT policy ACCEPT",
                        "ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
                        "ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
                        "ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
                        "ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
                        "ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
                        "ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
                        "ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",
                        "ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",
                        "ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50030",
                        "ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50070",
			"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50090",
			"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50075",
                        "ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 13",
                        "ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 14",
                        "ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 17",
                        "ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 18",
                        "ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 13",
                        "ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 14",
                        "ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 17",
                        "ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 18",
                        "ip filter chain INPUT rule append tail target DROP protocol udp dest-port 5353",
                        "ip filter enable"
		);
	if ($port) {
	foreach my $host (keys %$port) {
                push(@cmds,"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50060 source-addr $$port{$host} /32",
			   "ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50071 source-addr $$port{$host} /32",
			   "ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50076 source-addr $$port{$host} /32",
			);
        }	
		push(@cmds,"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50060",
			   "ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50071",
			   "ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50076"
			);
	}

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
			@cmd=(	"no username $user disable");
			my $type=$password if ($password);
			push(@cmd,"username $user password 0 $$prop{$user}{password}{0}") if ($$prop{$user}{password}{0});
		       	push(@cmd,"username $user password 7 $$prop{$user}{password}{7}") if ($$prop{$user}{password}{7});	
			#	"username $user password $password"
			push(@cmd,"username $user password $password") if (!($$prop{$user}{password}{0} || $$prop{$user}{password}{7}));
			 
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
	foreach my $type (keys %$adaptor) {
		my $UC=uc($type);
		$UC="TCP" if $UC=~/\s*TCPFIX\s*/;
		$UC="RADIUS" if $UC=~/\s*PILOTPACKET\s*/;
        	push (@cmds,"collector modify-instance 1 add-adaptor $type",
		"collector modify-instance 1 modify-adaptor $type add-port $$adaptor{$type}{port}",
		"collector modify-instance 1 modify-adaptor $type backup-file-system hostname 127.0.0.1",
   		"collector modify-instance 1 modify-adaptor $type backup-file-system port 9000",
		"collector modify-instance 1 modify-adaptor $type backup-file-system user admin",
   		"collector modify-instance 1 modify-adaptor $type bin-size 300",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-clear-interval 1",
		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} timezone \"\"",
		"collector modify-instance 1 modify-adaptor $type peak-flow-alarm-clear-interval 1",
		"collector modify-instance 1 modify-adaptor $type peak-flow-alarm-raise-interval 1",
		"collector modify-instance 1 modify-adaptor $type prorate disable",
		"collector modify-instance 1 modify-adaptor $type no-data-alarm-repeat 900",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-raise-interval 1",
   		"collector modify-instance 1 modify-adaptor $type drop-alarm-threshold 10",
   		"collector modify-instance 1 modify-adaptor $type file-format binary",
   		"collector modify-instance 1 modify-adaptor $type file-system hdfs-seq-file",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} adapter-profile none",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} filter-sourceIP disable",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} router-name \"\"",
   		"collector modify-instance 1 modify-adaptor $type modify-port $$adaptor{$type}{port} socket-IP 0.0.0.0",
   		"collector modify-instance 1 modify-adaptor $type num-bins 2",
		"collector modify-instance 1 modify-adaptor $type auto-bin-slide enable",
		#"collector modify-instance 1 modify-adaptor $type file-format binaryCompression",
   		"collector modify-instance 1 modify-adaptor $type num-objects 1000000");
		#if ($count>1) {
		#	my $i=1;
                #	while($i<=$count) {
   		push(@cmds,"collector modify-instance 1 modify-adaptor $type output-directory /data/collector/$instanceID/output/$type/%y/%m/%d/%h/%mi/$$prop{DCName}.$UC.");
		#		$i++;
		#	}

		#} else {
			
		#	push(@cmds,"collector modify-instance $instanceID modify-adaptor $type output-directory /data/collector/output/$type/%y/%m/%d/%h/%mi/$$prop{DCName}.$UC.");
	
		#}
		
   		push(@cmds,"collector modify-instance 1 modify-adaptor $type stack-log-level 0",
   			   "collector modify-instance 1 modify-adaptor $type timeout $$adaptor{$type}{timeout}");
	}

	}	
                push(@cmds,"pm liveness grace-period 600",
			"collector modify-instance 1 modify-adaptor pilotPacket num-objects 500000",
			"collector modify-instance 1 modify-adaptor ipfix peak-flow-alarm-threshold 20000",
			"collector modify-instance 1 modify-adaptor tcpfix peak-flow-alarm-threshold 30000",
			"collector modify-instance 1 modify-adaptor pilotPacket peak-flow-alarm-threshold 10000",
			"collector modify-instance 1 modify-adaptor ipfix attribute-binning enable",
			"collector modify-instance 1 modify-adaptor pilotPacket attribute-binning disable",
			"collector modify-instance 1 modify-adaptor tcpfix attribute-binning disable",
			"internal set modify \- /nr/collector/instance/1/adaptor/ipfix/max_bin_file_size value uint32 1",
			"internal set modify \- /pm/process/collector/term_action value name  /nr/collector/actions/terminate",
   			"pm process collector launch auto",
   			"pm process collector launch enable",
			"pm process collector launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib",
   			"pm process collector launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar:/opt/tms/java/MemSerializer.jar",
   			#"pm process collector launch environment set LD_PRELOAD \"\"",
			#"no pm process collector launch environment set LD_PRELOAD",
   			# Disable Partial calculation #
			"internal set modify - /stats/config/chd/interval_average_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_total_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_max_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_prorated_flow/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_dropped_flow/calc_partial value bool false",

			"internal set modify - /stats/config/chd/interval_average_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_total_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_max_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_prorated_flow_hour/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_dropped_flow_hour/calc_partial value bool false",

			"internal set modify - /stats/config/chd/interval_average_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_total_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_max_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_prorated_flow_day/calc_partial value bool false",
			"internal set modify - /stats/config/chd/interval_dropped_flow_day/calc_partial value bool false",
			"pm process collector launch environment set LIBHDFS_OPTS \-Xmx4096m",
   			"pm process collector launch relaunch auto",
			"pm process collector restart",
			"pmx register backup_hdfs",
			"pmx set backup_hdfs namenode UNINIT"

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
		"pmx register hadoop",
		"pmx register drbd",
		"pmx register oozie",
		# Configure HDFS Settings # Shifted to DC Namenode Specific section to avoid inclusion in NEC namenode #
		#"pmx register backup_hdfs",
		#"pmx set backup_hdfs namenode UNINIT"
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
		   "pmx set hadoop oozieServer $$prop{master}{ip}",
	# SU1 Scripting #
		   "internal set create - /tps/process/hadoop/attribute/mapred.tasktracker.map.tasks.maximum/value value string 10",
	# Following line added here just to include in DC Namenode Configs and preventing its addition to NEC/AC namenodes #
		   "internal set modify - /tps/process/hadoop/attribute/mapred.min.split.size/value value string 1288490189",
		   # Added on review by QA/ST on 29 OCT 2012 # Was commented, but including in SU1 ###
		   "internal set modify - /tps/process/hadoop/attribute/heartbeat.recheck.interval value string heartbeat.recheck.interval",
		   "internal set modify - /tps/process/hadoop/attribute/heartbeat.recheck.interval/value value string 130000",
	###
		   #"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 8080 not-source-addr $$prop{master}{ip} /32",
		   # OLD VALUES : Xmx4096m, 3221225472, 10, 4, Last set internal command was N/A, before 3.0 rc3 #
		   "internal set create - /tps/process/hadoop/attribute/mapred.child.java.opts/value value string -Xmx3584m",
		   #"internal set create - /tps/process/hadoop/attribute/mapred.min.split.size/value value string 1073741824",
		   #"internal set create - /tps/process/hadoop/attribute/mapred.tasktracker.map.tasks.maximum/value value string 10", # Was made 12 in between #
		   "internal set create - /tps/process/hadoop/attribute/mapred.tasktracker.reduce.tasks.maximum/value value string 4",
		   "internal set create - /tps/process/hadoop/attribute/io.sort.spill.percent/value value string 0.50",
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
	my $slef=shift;
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
		"no snmp-server community public",
		"snmp-server community $$prop{server}{community} ro",
		"snmp-server enable",
		"snmp-server enable communities",
		"snmp-server enable traps",
		#"snmp-server host $$prop{server}{ip} traps version 2c $$prop{server}{community}",
		"snmp-server listen enable",
		"snmp-server location $$prop{server}{location}",
		"snmp-server traps community $$prop{server}{community}",
		"snmp-server traps event HDFS-namenode-status",
		"snmp-server traps event no-collector-data",
		"snmp-server traps event collector-data-resume",
		"snmp-server traps event collector-dropped-flow-alarm-cleared",
		"snmp-server traps event collector-dropped-flow-thres-crossed",
		"snmp-server traps event cpu-util-high",
		"snmp-server traps event cpu-util-ok",
		"snmp-server traps event disk-io-high",
		"snmp-server traps event disk-space-low",
		"snmp-server traps event disk-space-ok",
		"snmp-server traps event interface-down",
		"snmp-server traps event interface-up",
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
		"stats alarm fs_mnt falling clear-threshold 10",
		"stats alarm fs_mnt falling error-threshold 7",
		"stats alarm memory_pct_used enable",
		"stats alarm cpu_util_indiv rate-limit count long 250",
		"stats alarm cpu_util_indiv rate-limit count medium 150",
		"stats alarm fs_mnt rising error-threshold 7",
		"stats alarm disk_io rising error-threshold 81920",
		"stats alarm disk_io rising clear-threshold 51200",
		"stats alarm intf_util rising error-threshold 1572864000",
		"stats alarm intf_util rising clear-threshold 1258291200",
		"stats alarm paging rising error-threshold 16000",
		"internal set modify - /stats/config/alarm/cpu_util_indiv/trigger/node_pattern value name /system/cpu/all/busy_pct",
		"internal set modify - /stats/config/sample/disk_io/interval value duration_sec 3600",
		"internal set create - \"/stats/config/alarm/fs_mnt/trigger/node_patterns/\\\\/system\\/fs\\\\/mount\\/\\\\\\\\\\\\/data\\\\/bytes-percent-free\" value name \"/system/fs/mount/\\/data/bytes-percent-free\"",
		#"internal set create - \"/stats/config/alarm/fs_mnt/trigger/node_patterns/\\\\/system\\/fs\\\\/mount\\/\\\\\\\\\\\\/data\\\\\\\\\\\\/hadoop-admin\\\\/bytes-percent-free\" value name \"/system/fs/mount/\\/data\\/hadoop-admin/bytes-percent-free\"",
		"stats alarm cpu_util_indiv rising clear-threshold 85",
		"stats alarm cpu_util_indiv rising error-threshold 90",
		"internal set modify - /stats/config/sample/disk_io/interval value duration_sec 3600",
	#---SU1 changes-----#
		"snmp traps event data-transfer-stall",
		"snmp traps event data-transfer-stall-alarm-cleared",
		"snmp-server traps event input-data-missing-task-ok",
		"snmp-server traps event input-data-missing-task-failed",
		"snmp-server traps event invalid-record-thresh-trap",
		"snmp-server traps event invalid-record-thresh-cleared",
		"snmp-server traps event input-data-not-usable-task-ok",
		"snmp-server traps event input-data-not-usable-task-failed",
		# Adding /data/hadoop-admin alarm for collectors and Data Nodes#
		"internal set create - \"/stats/config/alarm/fs_mnt/trigger/node_patterns/\\\\/system\\/fs\\\\/mount\\/\\\\\\\\\\\\/data\\\\\\\\\\\\/hadoop-admin\\\\/bytes-percent-free\" value name \"/system/fs/mount/\\/data\\/hadoop-admin/bytes-percent-free\"",
	#--------------------------------------------------------------------------------------------#
#		"pm process statsd restart"
	);

	my $snmpsrv=$$prop{server};
	foreach my $entry(keys %$snmpsrv) {
	# Sucks!!
	next if ($entry !~ m/\d+/);
	       push (@cmds, "no snmp-server host $$snmpsrv{$entry}{ip} disable");
	       push (@cmds, "snmp-server host $$snmpsrv{$entry}{ip} traps version 2c $$prop{server}{community}");
	}
	push (@cmds ,"pm process statsd restart");


	chomp @cmds;
	return @cmds;
}



# Provide reference of a hash for Oozie section properties
sub oozie {
        my $self=shift;
        my $prop=shift;
        my @cmds=();
	#my $time=time();
	my $time=`date +%Y-%m-%dT%H:00Z`;
	#my $hour=$4 if ($startTime=~(/(\d{4,4})\-(\d{2,2})\-(\d{2,2})T(\d{2,2})\:(\d{2,2})Z/))
	my $timeDSet=$time;
	my $timeJob=$time;
	#my $timeDSet=`date -v +1H +%Y-%m-%dT%H:00Z`;
	#my $timeJob=`date -v +2H +%Y-%m-%dT%H:00Z`;

	#$timeDSet=strftime "%Y-%m-%dT%H:00Z", localtime($timeDSet);
	#$timeJob=strftime "%Y-%m-%dT%H:00Z", localtime($timeJob);

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
				next if($job=~/CleanupAtlas/);
				push (@cmds, "pmx subshell oozie set job $job action $action attribute timeout $$actions{$action}{attribute}{timeout}");
			}

		push (@cmds, "pmx subshell oozie set job $job attribute jobStart $timeJob");
		push (@cmds, "pmx subshell oozie set job $job attribute jobEnd 2099-12-31T00:00Z");
	}
	
	if (! $$jobs{CubeExporter}) {	
	push (@cmds,	#"pmx register backup_hdfs",
		        #"pmx set backup_hdfs namenode UNINIT",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute binaryInput true",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute outputDataset atlas_subib",
		### SU1 Update ###
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute inputDatasets atlas_selfipcleanup1",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute validMdnLength 10",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute invalidRecordsThreshold 10",
			"pmx subshell oozie set job Atlas attribute lastSuccessPath /data/local/LastSucessfulOutput",
		#####
			#"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute timeout -1",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute mainClass com.guavus.mapred.atlas.job.subscriberib.SubscriberIBCreator",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute snapshotDatasets atlas_subib",
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute configFile /opt/etc/oozie/AtlasCubes/SubscriberIBCreator.xml",
			"pmx subshell oozie set job Atlas action WngIBCreator attribute binaryInput true",
			"pmx subshell oozie set job Atlas action WngIBCreator attribute outputDataset atlas_wngib",

			##"pmx subshell oozie set job Atlas action WngIBCreator attribute timeout -1",
			"pmx subshell oozie set job Atlas action WngIBCreator attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action WngIBCreator attribute mainClass com.guavus.mapred.atlas.job.wng.WngIBCreator",
			"pmx subshell oozie set job Atlas action WngIBCreator attribute snapshotDatasets atlas_wngib",
			"pmx subshell oozie set job Atlas action WngIBCreator attribute configFile /opt/etc/oozie/AtlasCubes/WngIBCreator.xml",
			"pmx subshell oozie set job Atlas action BaseCubes attribute outputDataset atlas_basecube",
			"pmx subshell oozie set job Atlas action BaseCubes attribute binaryInput true",
			"pmx subshell oozie set job Atlas action BaseCubes attribute mainClass com.guavus.mapred.atlas.job.BaseCubeJob.AtlasCubes",
			#"pmx subshell oozie set job Atlas action BaseCubes attribute timeout -1"
			
		);

	push (@cmds, 
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute binaryInput true",
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute outputDataset atlas_ipportcleanup",
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute inputDatasets atlas_subib",
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute mainClass com.guavus.mapred.atlas.job.SubscriberibIpPortCleanup.Main",
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
			"pmx subshell oozie set job Atlas action SubscriberibIpPortCleanup attribute timeout 0",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute binaryInput true",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute outputDataset atlas_selfipcleanup",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute inputDatasets atlas_ipportcleanup",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute mainClass com.guavus.mapred.atlas.job.SubscriberibSelfIpCleanup.Main",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
			"pmx subshell oozie set job Atlas action SubscriberibSelfIpCleanup attribute timeout 0",
			"pmx subshell oozie add dataset atlas_selfipcleanup",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute startOffset 1",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute frequency 60",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute path /data/output/SubscriberIBSelfIpCleanup/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_selfipcleanup attribute pathType hdfs",
			"pmx subshell oozie add dataset atlas_ipportcleanup",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute startOffset 0",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute frequency 60",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute endOffset 0",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute path /data/output/SubscriberIBIpPortCleanup/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_ipportcleanup attribute pathType hdfs"

		);





		my $c=1;
                # input Datasets
                while($c<=$count) {
                push(@cmds,
			"pmx subshell oozie set job Atlas action SubscriberIBCreator attribute inputDatasets atlas_radius_$c",
			#"pmx subshell oozie set job Atlas action WngIBCreator attribute inputDatasets atlas_wng_$c",

			"pmx subshell oozie set job Atlas action BaseCubes attribute inputDatasets atlas_ipfix_$c",
			"pmx subshell oozie set job Atlas action BaseCubes attribute inputDatasets atlas_tcpfix_$c",
			# TopUrl commented for 3.0rc3 #
			#"pmx subshell oozie set job TopUrl action HHUrl attribute inputDatasets atlas_ipfix_$c",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_ipfix_$c",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_tcpfix_$c",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_radius_$c",
			#"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupDatasets atlas_wng_$c"
	### SU1 Changes ###
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_ipfix_$c",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_tcpfix_$c",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_radius_$c",
	###
		);
			$c++;
		}

		push(@cmds,
			"pmx subshell oozie set job Atlas action BaseCubes attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action BaseCubes attribute configFile /opt/etc/oozie/AtlasCubes/BaseCubes.xml",
			"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute outputDataset atlas_subbytes",
			"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute inputDatasets atlas_basecube",
			"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator",
			"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute snapshotDatasets atlas_subbytes",
			#"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute timeout 0",
			"pmx subshell oozie set job Atlas action SubcrBytesAgg attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
			"pmx subshell oozie set job Atlas action TopN attribute outputDataset atlas_topn",
			"pmx subshell oozie set job Atlas action TopN attribute mainClass com.guavus.mapred.atlas.job.TopNJob.TopN",
			"pmx subshell oozie set job Atlas action TopN attribute topNHApp 300",
			"pmx subshell oozie set job Atlas action TopN attribute topDev 200",
			"pmx subshell oozie set job Atlas action TopN attribute inputDatasets atlas_basecube",
			"pmx subshell oozie set job Atlas action TopN attribute topApp 300",
			"pmx subshell oozie set job Atlas action TopN attribute topSP 300",
		### SU1 Changes
			#"pmx subshell oozie set job Atlas action TopN attribute topUrlBins 300",
			"pmx subshell oozie set job Atlas action TopN attribute topUnCatUAs 1000",
			"pmx subshell oozie set job Atlas action TopN attribute topUnCatUrls 1000",
		### 
			"pmx subshell oozie set job Atlas action TopN attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action TopN attribute configFile /opt/etc/oozie/AtlasCubes/TopN.json",
			#"pmx subshell oozie set job Atlas action TopN attribute timeout 0",
			"pmx subshell oozie set job Atlas action SubcrDev attribute outputDataset atlas_subdev",
			"pmx subshell oozie set job Atlas action SubcrDev attribute inputDatasets atlas_basecube",
			"pmx subshell oozie set job Atlas action SubcrDev attribute mainClass com.guavus.mapred.atlas.job.subdevmapib.SubDevMapIBCreator",
			"pmx subshell oozie set job Atlas action SubcrDev attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			#"pmx subshell oozie set job Atlas action SubcrDev attribute timeout 0",
			"pmx subshell oozie set job Atlas action SubcrDev attribute snapshotDatasets atlas_subdev",
			"pmx subshell oozie set job Atlas action SubcrDev attribute configFile /opt/etc/oozie/AtlasCubes/AtlasCubes.xml",
			"pmx subshell oozie set job Atlas action Rollup attribute outputDataset atlas_rollup",
			"pmx subshell oozie set job Atlas action Rollup attribute inputDatasets atlas_basecube",
			"pmx subshell oozie set job Atlas action Rollup attribute mainClass com.guavus.mapred.atlas.job.rollup.Main",
			"pmx subshell oozie set job Atlas action Rollup attribute topnDataset atlas_topn",
			"pmx subshell oozie set job Atlas action Rollup attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job Atlas action Rollup attribute configFile /opt/etc/oozie/AtlasCubes/Rollup.json",
			#"pmx subshell oozie set job Atlas action Rollup attribute timeout 0"
		);
		
		my $c=1;
		# atlas_radius
		while($c<=$count) {
		push(@cmds,
			"pmx subshell oozie add dataset atlas_radius_$c",
			"pmx subshell oozie set dataset atlas_radius_$c attribute startOffset 12",
			"pmx subshell oozie set dataset atlas_radius_$c attribute frequency 5",
			"pmx subshell oozie set dataset atlas_radius_$c attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_radius_$c attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_radius_$c attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_radius_$c attribute path /data/collector/$c/output/pilotPacket/%Y/%M/%D/%H/%mi",
			"pmx subshell oozie set dataset atlas_radius_$c attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_radius_$c attribute pathType hdfs"
		);
			$c++;
		}

		#$c=1;
		#atlas_wng
		#while($c<=$count) {	
                #push(@cmds, 
		#	"pmx subshell oozie add dataset atlas_wng_$c",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute startOffset 12",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute frequency 5",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute endOffset 1",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute doneFile _DONE",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute outputOffset 0",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute path /data/collector/$c/output/wng/%Y/%M/%D/%H/%mi",
		#	#"pmx subshell oozie set dataset atlas_wng_$c attribute startTime $$prop{dataset}{atlas_wng}{attribute}{startTime}",
		#	"pmx subshell oozie set dataset atlas_wng_$c attribute pathType hdfs"
		#);
		#	$c++;
		#}

		push (@cmds,
			"pmx subshell oozie add dataset atlas_subib",
			"pmx subshell oozie set dataset atlas_subib attribute startOffset 0",
			"pmx subshell oozie set dataset atlas_subib attribute frequency 60",
			"pmx subshell oozie set dataset atlas_subib attribute endOffset 0",
			"pmx subshell oozie set dataset atlas_subib attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_subib attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_subib attribute path /data/output/SubscriberIB/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_subib attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_subib attribute pathType hdfs",
			"pmx subshell oozie add dataset atlas_wngib",
			"pmx subshell oozie set dataset atlas_wngib attribute startOffset 1",
			"pmx subshell oozie set dataset atlas_wngib attribute frequency 60",
			"pmx subshell oozie set dataset atlas_wngib attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_wngib attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_wngib attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_wngib attribute path /data/output/WngIB/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_wngib attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_wngib attribute pathType hdfs"
		);
		$c=1;
		# atlas_ipfix
		while($c<=$count) {
		push(@cmds, 
			"pmx subshell oozie add dataset atlas_ipfix_$c",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute startOffset 12",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute frequency 5",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute path /data/collector/$c/output/ipfix/%Y/%M/%D/%H/%mi/*",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_ipfix_$c attribute pathType hdfs"
		);
			$c++;
		}

		$c=1;
		# atlas_tcpfix
		while($c<=$count) {
		push(@cmds, 
			"pmx subshell oozie add dataset atlas_tcpfix_$c",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute startOffset 12",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute frequency 5",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute path /data/collector/$c/output/tcpfix/%Y/%M/%D/%H/%mi",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_tcpfix_$c attribute pathType hdfs"
		);
			$c++;
		}

		push (@cmds,
			"pmx subshell oozie add dataset atlas_basecube",
			"pmx subshell oozie set dataset atlas_basecube attribute startOffset 0",
			"pmx subshell oozie set dataset atlas_basecube attribute frequency 60",
			"pmx subshell oozie set dataset atlas_basecube attribute endOffset 0",
			"pmx subshell oozie set dataset atlas_basecube attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_basecube attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_basecube attribute path /data/output/AtlasBaseCubes/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_basecube attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_basecube attribute pathType hdfs",
			"pmx subshell oozie add dataset atlas_topn",
			"pmx subshell oozie set dataset atlas_topn attribute startOffset 0",
			"pmx subshell oozie set dataset atlas_topn attribute frequency 60",
			"pmx subshell oozie set dataset atlas_topn attribute endOffset 0",
			"pmx subshell oozie set dataset atlas_topn attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_topn attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_topn attribute path /data/output/TopN/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_topn attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_topn attribute pathType hdfs",
			"pmx subshell oozie add dataset atlas_subbytes",
			"pmx subshell oozie set dataset atlas_subbytes attribute startOffset 1",
			"pmx subshell oozie set dataset atlas_subbytes attribute frequency 60",
			"pmx subshell oozie set dataset atlas_subbytes attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_subbytes attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_subbytes attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_subbytes attribute path /data/output/AtlasSubcrBytes/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_subbytes attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_subbytes attribute pathType hdfs",
			"pmx subshell oozie add dataset atlas_subdev",
			"pmx subshell oozie set dataset atlas_subdev attribute startOffset 1",
			"pmx subshell oozie set dataset atlas_subdev attribute frequency 60",
			"pmx subshell oozie set dataset atlas_subdev attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_subdev attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_subdev attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_subdev attribute path /data/output/AtlasSubDevs/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_subdev attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_subdev attribute pathType hdfs",
			"pmx subshell oozie add dataset atlas_rollup",
			"pmx subshell oozie set dataset atlas_rollup attribute startOffset 0",
			"pmx subshell oozie set dataset atlas_rollup attribute frequency 60",
			"pmx subshell oozie set dataset atlas_rollup attribute endOffset 0",
			"pmx subshell oozie set dataset atlas_rollup attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_rollup attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_rollup attribute path /data/output/AtlasRollupCubes/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset atlas_rollup attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_rollup attribute pathType hdfs",
			"pmx subshell oozie add dataset DistcpCubes",
			"pmx subshell oozie set dataset DistcpCubes attribute startOffset 0",
			"pmx subshell oozie set dataset DistcpCubes attribute frequency 60",
			"pmx subshell oozie set dataset DistcpCubes attribute endOffset 0",
			"pmx subshell oozie set dataset DistcpCubes attribute doneFile _DONE",
			"pmx subshell oozie set dataset DistcpCubes attribute outputOffset 0",
			"pmx subshell oozie set dataset DistcpCubes attribute path /data/output/Cubes/$$prop{dataset}{common}{path}{attribute}{dcname}/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset DistcpCubes attribute startTime $timeDSet",
			"pmx subshell oozie set dataset DistcpCubes attribute pathType hdfs",


		### SU1 Changes ##
			"pmx subshell oozie set job TopNcp action DistcpAction attribute destDataset OfflineTopNtoNEC",
			"pmx subshell oozie set job TopNcp action DistcpAction attribute destNamenode $$prop{job}{Distcp}{action}{DistcpAction}{attribute}{destNamenode}",
			"pmx subshell oozie set job TopNcp action DistcpAction attribute flags -overwrite",
			"pmx subshell oozie set job TopNcp action DistcpAction attribute retrySleep 60",
			"pmx subshell oozie set job TopNcp action DistcpAction attribute safeDelay 5100",
			"pmx subshell oozie set job TopNcp action DistcpAction attribute srcDataset atlas_topn",
			"pmx subshell oozie set job TopNcp action DistcpAction attribute srcNamenode $$prop{job}{Distcp}{action}{DistcpAction}{attribute}{srcNamenode}",
		
			"pmx subshell oozie set job BackupDistcpNAP action BackupDistcpAction attribute bucketSize 3",
			"pmx subshell oozie set job BackupDistcpNAP action BackupDistcpAction attribute safeDelay 39600",
			"pmx subshell oozie set job BackupDistcpNAP action BackupDistcpAction attribute maxParallelThreads 2",
			"pmx subshell oozie set job BackupDistcpNAP action BackupDistcpAction attribute destNamenode $$prop{job}{Distcp}{action}{DistcpAction}{attribute}{destNamenode}",


			"pmx subshell oozie add dataset OfflineTopNtoNEC",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute doneFile _DONE",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute startTime $timeDSet",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute endOffset 0",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute frequency 60",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute outputOffset 0",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute path /data/OfflineTopN/$$prop{dataset}{common}{path}{attribute}{dcname}/%Y/%M/%D/%H",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute pathType hdfs",
			"pmx subshell oozie set dataset OfflineTopNtoNEC attribute startOffset 0",

			"pmx subshell oozie add dataset atlas_selfipcleanup1",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute startOffset 1",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute endOffset 1",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute frequency 60",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute doneFile _DONE",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute outputOffset 0",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute path /data/output/SubscriberIBSelfIpCleanup/%Y/%M/%D/%H/*",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute startTime $timeDSet",
			"pmx subshell oozie set dataset atlas_selfipcleanup1 attribute pathType hdfs",
			"pmx subshell oozie set job Distcp action DistcpAction attribute safeDelay 5100",
			"pmx subshell oozie set job Distcp action DistcpAction attribute retryCount -1",
		###


			"pmx subshell oozie set job Distcp action DistcpAction attribute destDataset DistcpCubes",
			"pmx subshell oozie set job Distcp action DistcpAction attribute destNamenode $$prop{job}{Distcp}{action}{DistcpAction}{attribute}{destNamenode}",
			"pmx subshell oozie set job Distcp action DistcpAction attribute retryCount 3",
			#"pmx subshell oozie set job Distcp action DistcpAction attribute timeout -1",
			"pmx subshell oozie set job Distcp action DistcpAction attribute srcNamenode $$prop{job}{Distcp}{action}{DistcpAction}{attribute}{srcNamenode}",
			"pmx subshell oozie set job Distcp action DistcpAction attribute srcDataset atlas_rollup",
			"pmx subshell oozie set job Distcp action DistcpAction attribute retrySleep 60",
			#"pmx subshell oozie set job TopUrl action HHUrl attribute outputDataset atlas_hhurl",
			#"pmx subshell oozie set job TopUrl action HHUrl attribute mainClass com.guavus.mapred.atlas.job.TopUrlJob.Main",
			##"pmx subshell oozie set job TopUrl action HHUrl attribute timeout -1",


			#"pmx subshell oozie set job TopUrl action HHUrl attribute topnDataset atlas_topn",
			#"pmx subshell oozie set job TopUrl action HHUrl attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			#"pmx subshell oozie set job TopUrl action HHUrl attribute configFile /opt/etc/oozie/TopUrl/HHUrl.json",
			#"pmx subshell oozie set job TopUrl action TopHHUrl attribute outputDataset atlas_topurl",
			#"pmx subshell oozie set job TopUrl action TopHHUrl attribute inputDatasets atlas_hhurl",
			#"pmx subshell oozie set job TopUrl action TopHHUrl attribute topUrlBins 10",
			#"pmx subshell oozie set job TopUrl action TopHHUrl attribute mainClass com.guavus.mapred.atlas.job.TopNUrl.Main",
			#"pmx subshell oozie set job TopUrl action TopHHUrl attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			#"pmx subshell oozie set job TopUrl action TopHHUrl attribute configFile /opt/etc/oozie/TopUrl/TopHHUrl.json",
			#"pmx subshell oozie add dataset atlas_hhurl",
			#"pmx subshell oozie set dataset atlas_hhurl attribute startOffset 0",
			#"pmx subshell oozie set dataset atlas_hhurl attribute frequency 60",
			#"pmx subshell oozie set dataset atlas_hhurl attribute endOffset 0",
			#"pmx subshell oozie set dataset atlas_hhurl attribute doneFile _DONE",
			#"pmx subshell oozie set dataset atlas_hhurl attribute outputOffset 0",
			#"pmx subshell oozie set dataset atlas_hhurl attribute path /data/output/HHUrl/%Y/%M/%D/%H",
			#"pmx subshell oozie set dataset atlas_hhurl attribute startTime $timeDSet",
			#"pmx subshell oozie set dataset atlas_hhurl attribute pathType hdfs",
			#"pmx subshell oozie add dataset atlas_topurl",
			#"pmx subshell oozie set dataset atlas_topurl attribute startOffset 0",
			#"pmx subshell oozie set dataset atlas_topurl attribute frequency 60",
			#"pmx subshell oozie set dataset atlas_topurl attribute endOffset 0",
			#"pmx subshell oozie set dataset atlas_topurl attribute doneFile _DONE",
			#"pmx subshell oozie set dataset atlas_topurl attribute outputOffset 0",
			#"pmx subshell oozie set dataset atlas_topurl attribute path /data/output/TopUrl/%Y/%M/%D/%H",
			#"pmx subshell oozie set dataset atlas_topurl attribute startTime $timeDSet",
			#"pmx subshell oozie set dataset atlas_topurl attribute pathType hdfs",
			"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute outputDataset MonthlyBytes",
			#"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute timeout -1",
			"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator",
			"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute configFile /opt/etc/oozie/SubscriberBytes/config.xml",
			"pmx subshell oozie set job SubscriberBytes action SubBytesMapRedAction attribute inputDatasets BytesAgg_month",
			"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute destDataset MonthlyBytesToNEC",
			"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute destNamenode $$prop{job}{SubscriberBytes}{action}{DistcpBytes}{attribute}{destNamenode}",
			"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute retryCount 1",
			#"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute timeout 0",
			"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute srcNamenode $$prop{job}{SubscriberBytes}{action}{DistcpBytes}{attribute}{srcNamenode}",
			"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute srcDataset MonthlyBytes",
			"pmx subshell oozie set job SubscriberBytes action DistcpBytes attribute retrySleep 60",
			"pmx subshell oozie add dataset BytesAgg_month",
			"pmx subshell oozie set dataset BytesAgg_month attribute startOffset 31",
			"pmx subshell oozie set dataset BytesAgg_month attribute frequency 1440",
			"pmx subshell oozie set dataset BytesAgg_month attribute endOffset 1",
			"pmx subshell oozie set dataset BytesAgg_month attribute doneFile _DONE",
			"pmx subshell oozie set dataset BytesAgg_month attribute outputOffset 0",
			"pmx subshell oozie set dataset BytesAgg_month attribute path /data/output/AtlasSubcrBytes/%Y/%M/%D/23",
			"pmx subshell oozie set dataset BytesAgg_month attribute startTime $timeDSet",
			"pmx subshell oozie set dataset BytesAgg_month attribute pathType hdfs",
			"pmx subshell oozie add dataset MonthlyBytes",
			"pmx subshell oozie set dataset MonthlyBytes attribute startOffset 0",
			"pmx subshell oozie set dataset MonthlyBytes attribute frequency 1",
			"pmx subshell oozie set dataset MonthlyBytes attribute frequencyUnit month",
			"pmx subshell oozie set dataset MonthlyBytes attribute endOffset 0",
			"pmx subshell oozie set dataset MonthlyBytes attribute doneFile _DONE",
			"pmx subshell oozie set dataset MonthlyBytes attribute outputOffset 0",
			"pmx subshell oozie set dataset MonthlyBytes attribute path /data/output/MonthlyBytes/%Y/%M",
			"pmx subshell oozie set dataset MonthlyBytes attribute startTime $timeDSet",
			"pmx subshell oozie set dataset MonthlyBytes attribute pathType hdfs",
			"pmx subshell oozie add dataset MonthlyBytesToNEC",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute startOffset 0",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute frequency 1",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute frequencyUnit month",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute endOffset 0",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute doneFile _DONE",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute outputOffset 0",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute path /data/output/MonthlyBytes/$$prop{dataset}{common}{path}{attribute}{dcname}/%Y/%M",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute startTime $timeDSet",
			"pmx subshell oozie set dataset MonthlyBytesToNEC attribute pathType hdfs",
			"pmx subshell oozie set job TopSubcr action BytesAgg attribute outputDataset WeeklyBytes",
			#"pmx subshell oozie set job TopSubcr action BytesAgg attribute timeout -1",
			"pmx subshell oozie set job TopSubcr action BytesAgg attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job TopSubcr action BytesAgg attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator",
			"pmx subshell oozie set job TopSubcr action BytesAgg attribute configFile /opt/etc/oozie/TopSubcr/config.xml",
			"pmx subshell oozie set job TopSubcr action BytesAgg attribute inputDatasets BytesAgg",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute outputDataset TopSubcrWeekly",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute inputDatasets WeeklyBytes",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute topSubcrFlows 10000",
			#"pmx subshell oozie set job TopSubcr action TopSubscribers attribute timeout 0",
			#"pmx subshell oozie set job TopSubcr action TopSubscribers attribute topSubcrBytesFlows 10000",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute mainClass com.guavus.mapred.atlas.job.TopSubscriber.TopSubscriber",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute configFile /opt/etc/oozie/TopSubcr/TopSubscribers.xml",
			"pmx subshell oozie set job TopSubcr action TopSubscribers attribute topSubcrBytes 10000",
			"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute outputDataset TopSubcrMerge",
			#"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute timeout 0",
			"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute mainClass com.guavus.mapred.atlas.job.TopSubscriberMerge.TopSubscriberMerge",
			"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute configFile /opt/etc/oozie/TopSubcr/config.xml",
			"pmx subshell oozie set job TopSubcr action TopSubcrMerge attribute inputDatasets TopSubcrWeekly",
			"pmx subshell oozie add dataset BytesAgg",
			"pmx subshell oozie set dataset BytesAgg attribute startOffset 7",
			"pmx subshell oozie set dataset BytesAgg attribute frequency 1440",
			"pmx subshell oozie set dataset BytesAgg attribute endOffset 1",
			"pmx subshell oozie set dataset BytesAgg attribute doneFile _DONE",
			"pmx subshell oozie set dataset BytesAgg attribute outputOffset 0",
			"pmx subshell oozie set dataset BytesAgg attribute path /data/output/AtlasSubcrBytes/%Y/%M/%D/23",
			"pmx subshell oozie set dataset BytesAgg attribute startTime $timeDSet",
			"pmx subshell oozie set dataset BytesAgg attribute pathType hdfs",
			"pmx subshell oozie add dataset WeeklyBytes",
			"pmx subshell oozie set dataset WeeklyBytes attribute startOffset 0",
			"pmx subshell oozie set dataset WeeklyBytes attribute frequency 10080",
			"pmx subshell oozie set dataset WeeklyBytes attribute endOffset 0",
			"pmx subshell oozie set dataset WeeklyBytes attribute doneFile _DONE",
			"pmx subshell oozie set dataset WeeklyBytes attribute outputOffset 0",
			"pmx subshell oozie set dataset WeeklyBytes attribute path /data/output/BytesAggWeekly/%Y/%M/%D",
			"pmx subshell oozie set dataset WeeklyBytes attribute startTime $timeDSet",
			"pmx subshell oozie set dataset WeeklyBytes attribute pathType hdfs",
			"pmx subshell oozie add dataset TopSubcrWeekly",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute startOffset 0",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute frequency 10080",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute endOffset 0",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute doneFile _DONE",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute outputOffset 0",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute path /data/output/TopSubcribers/%Y/%M/%D",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute startTime $timeDSet",
			"pmx subshell oozie set dataset TopSubcrWeekly attribute pathType hdfs",
			"pmx subshell oozie add dataset TopSubcrMerge",
			"pmx subshell oozie set dataset TopSubcrMerge attribute startOffset 2",
			"pmx subshell oozie set dataset TopSubcrMerge attribute frequency 10080",
			"pmx subshell oozie set dataset TopSubcrMerge attribute endOffset 0",
			"pmx subshell oozie set dataset TopSubcrMerge attribute doneFile _DONE",
			"pmx subshell oozie set dataset TopSubcrMerge attribute outputOffset 0",
			"pmx subshell oozie set dataset TopSubcrMerge attribute path /data/output/TopSubcrMerge/%Y/%M/%D",
			"pmx subshell oozie set dataset TopSubcrMerge attribute startTime $timeDSet",
			"pmx subshell oozie set dataset TopSubcrMerge attribute pathType hdfs",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute outputDataset ConsistentSubcr",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute inputDatasets TopSubcrMerge",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute topSubcrFlows 100",
			#"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute timeout -1",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute topSubcrBytesFlows 100",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute mainClass com.guavus.mapred.atlas.job.ConsistentTopSubscriber.ConsistentTopSubscriber",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute configFile /opt/etc/oozie/ConsistentTopSubcr/ConsistentSubcrs.xml",
			"pmx subshell oozie set job ConsistentTopSubcr action ConsistentSubcrs attribute topSubcrBytes 100",
			"pmx subshell oozie set job ConsistentTopSubcr action CopyIB attribute srcDataset ConsistentSubcr",
			"pmx subshell oozie add dataset ConsistentSubcr",
			"pmx subshell oozie set dataset ConsistentSubcr attribute startOffset 0",
			"pmx subshell oozie set dataset ConsistentSubcr attribute frequency 10080",
			"pmx subshell oozie set dataset ConsistentSubcr attribute endOffset 0",
			"pmx subshell oozie set dataset ConsistentSubcr attribute doneFile _DONE",
			"pmx subshell oozie set dataset ConsistentSubcr attribute outputOffset 0",
			"pmx subshell oozie set dataset ConsistentSubcr attribute path /data/output/ConsistentTopSubcr/%Y/%M/%D",
			"pmx subshell oozie set dataset ConsistentSubcr attribute startTime $timeDSet",
			"pmx subshell oozie set dataset ConsistentSubcr attribute pathType hdfs",
			"pmx subshell oozie set job CleanupCollector action CleanupDatasetAction attribute cleanupOffset 18",


			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute cleanupOffset 5",
	### SU1 Changes ###
			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute collectorIPs 192.168.0.67",
			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute collectorIPs 192.168.0.70",
			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute collectorIPs 192.168.0.83",
			"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute collectorIPs 192.168.0.86",
	###

			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupOffset $$prop{job}{CleanupAtlas}{action}{CleanupAction}{attribute}{cleanupOffset}",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_basecube",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_topn",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_subbytes",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_subdev",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_rollup",
			#"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_hhurl",
			#"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_topurl",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets WeeklyBytes",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets TopSubcrWeekly",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets TopSubcrMerge",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets ConsistentSubcr",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets MonthlyBytes",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_wngib",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_subib",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_ipportcleanup",
			"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets atlas_selfipcleanup",

			# Cleanup job added to clean monthly datasets #
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupOffset 33",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets BytesAgg_month",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets TopSubcrWeekly",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_ipportcleanup",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_wngib",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_subdev",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets TopSubcrMerge",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_subbytes",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets MonthlyBytes",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets WeeklyBytes",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_subib",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_basecube",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets ConsistentSubcr",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_selfipcleanup",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_topn",
			"pmx subshell oozie set job CleanupMonthlyData action CleanupDatasetAction attribute cleanupDatasets atlas_rollup"
			);
		### Following sectional commands added on behalf of Rajesh Gupta's confirmation ###
		push (@cmds, 	"pmx subshell oozie set job Atlas action WngIBCreator attribute inputDatasets atlas_wng",
				"pmx subshell oozie add dataset atlas_wng",
				"pmx subshell oozie set dataset atlas_wng attribute startOffset 12",
				"pmx subshell oozie set dataset atlas_wng attribute frequency 5",
				"pmx subshell oozie set dataset atlas_wng attribute endOffset 1",
                                "pmx subshell oozie set dataset atlas_wng attribute doneFile _DONE",
                                "pmx subshell oozie set dataset atlas_wng attribute outputOffset 0",
                                "pmx subshell oozie set dataset atlas_wng attribute path /data/collector/output/wng/%Y/%M/%D/%H/%mi",
                                "pmx subshell oozie set dataset atlas_wng attribute startTime $timeDSet",
                                "pmx subshell oozie set dataset atlas_wng attribute pathType hdfs",
					

			);

	} else {
			my $src="$$prop{job}{CubeExporter}{action}{ExporterAction}{attribute}{src}";
			my $ExporterSrcDataset="Cubes_"."$src";

		push (@cmds,	"pmx subshell oozie set job CubeExporter action ExporterAction attribute binInterval 3600",
				"pmx subshell oozie set job CubeExporter action ExporterAction attribute aggregationInterval 3600",
				"pmx subshell oozie set job CubeExporter action ExporterAction attribute jarName /opt/tms/java/Exporter-atlas3.0.jar",
				"pmx subshell oozie set job CubeExporter action ExporterAction attribute className com.guavus.exporter.Exporter",
				### Following command taken care in provision DC on AC script. ###
  				#"pmx subshell oozie set job CubeExporter action ExporterAction attribute srcDatasets $ExporterSrcDataset",
  				"pmx subshell oozie set job CubeExporter action ExporterAction attribute instaPort 11111",
 				"pmx subshell oozie set job CubeExporter action ExporterAction attribute minTimeout $$prop{job}{CubeExporter}{action}{ExporterAction}{attribute}{minTimeout}",
 				"pmx subshell oozie set job CubeExporter action ExporterAction attribute solutionName atlas",
 				"pmx subshell oozie set job CubeExporter action ExporterAction attribute instaHost $$prop{job}{CubeExporter}{action}{ExporterAction}{attribute}{instaHost}",
  				"pmx subshell oozie set job CubeExporter action ExporterAction attribute maxTimeout $$prop{job}{CubeExporter}{action}{ExporterAction}{attribute}{maxTimeout}",
  				"pmx subshell oozie set job CubeExporter action ExporterAction attribute fileType Seq",
  				"pmx subshell oozie set job CubeExporter action ExporterAction attribute retrySleep 300",

  				#"pmx subshell oozie add dataset $ExporterSrcDataset",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute startOffset 0",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute frequency 60",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute endOffset 0",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute doneFile _DONE",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute outputOffset 0",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute path /data/output/Cubes/$src/%Y/%M/%D/%H",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute startTime $$prop{dataset}{Cubes_src}{attribute}{startTime}",
  				#"pmx subshell oozie set dataset $ExporterSrcDataset attribute pathType hdfs",

  				"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute outputDataset SubscriberSegment",
  				"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
  				"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute mainClass com.guavus.mapred.atlas.job.SubscriberSegment.SubscriberSegment",
  				"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute configFile /opt/etc/oozie/SubscriberSegment/config.xml",
  				#"pmx subshell oozie set job SubscriberSegment action SubSegMapRedAction attribute inputDatasets SubcrBytes_"."$src",
  				"pmx subshell oozie set job SubscriberSegment action PushIB attribute ibName subseg.id.map",
  				"pmx subshell oozie set job SubscriberSegment action PushIB attribute srcDataset SubscriberSegment",
				

				# Following added for 3.0rc3 10/10/2012 #
			#----------------------------------------------------------------------------------------------------------------#
				"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute inputDataset SubscriberSegment",
				"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute outputDataset SubscriberSegmentMPH",
				"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute  jarFile /opt/tms/java/CubeCreator-atlas3.0.jar",
				"pmx subshell oozie set job SubscriberSegment action SegmentMPH attribute  mainClass com.guavus.mapred.atlas.job.SubscriberSegment.SubscriberSegment",
				"pmx subshell oozie set job SubscriberSegment action PushIB attribute ibName subseg.id.map",
				"pmx subshell oozie set job SubscriberSegment action PushIB attribute srcDataset SubscriberSegmentMPH",

				#"pmx subshell oozie set job AggregationJobDaily action HadoopJobAction attribute outputDataset AggregateRollupDaily",
				#"pmx subshell oozie set job AggregationJobDaily action HadoopJobAction attribute configFile /opt/etc/oozie/AggregateJob/config.json",
				#"pmx subshell oozie set job AggregationJobDaily action HadoopJobAction attribute timeout -1",
				#Remaining AggregationJobDaily config along with one dataset (aggcubes_<DCName>)is added in "ProvisioDConNEC" script#

			#------Following Section is Commented for now as it is not tested by ST yet, 'll be required in Future------------#
				#"pmx subshell oozie add dataset AggregateRollupDaily",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute startOffset 6",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute endOffset 0",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute doneFile _DONE",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute outputOffset 0",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute path /data/output/AtlasRollupCubeDaily/%Y/%M/%D",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute pathType hdfs",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute frequency 1",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute frequencyUnit day",
				#"pmx subshell oozie set dataset AggregateRollupDaily attribute startTime $timeDSet",

				"pmx subshell oozie add dataset SubscriberSegmentMPH",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute startOffset 0",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute frequency 1",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute frequencyUnit month",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute endOffset 0",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute doneFile _DONE",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute outputOffset 0",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute path /data/output/SegmentsMPH/%Y/%M",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute startTime $timeDSet",
				"pmx subshell oozie set dataset SubscriberSegmentMPH attribute pathType hdfs",
			#----------------------------------------------------------------------------------------------------------------#
				# Following added in provisioDConNEC script #
				#
				#"pmx subshell oozie add dataset SubcrBytes_"."$src",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute startOffset 0",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute frequency 1",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute frequencyUnit month",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute endOffset 0",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute doneFile _DONE",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute outputOffset 0",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute path /data/output/MonthlyBytes/$src/%Y/%M",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute startTime $$prop{dataset}{SubcrBytes_src}{attribute}{startTime}",
  				#"pmx subshell oozie set dataset SubcrBytes_"."$src attribute pathType hdfs",
  				"pmx subshell oozie add dataset SubscriberSegment",
  				"pmx subshell oozie set dataset SubscriberSegment attribute startOffset 0",
  				"pmx subshell oozie set dataset SubscriberSegment attribute frequency 1",
  				"pmx subshell oozie set dataset SubscriberSegment attribute frequencyUnit month",
  				"pmx subshell oozie set dataset SubscriberSegment attribute endOffset 0",
  				"pmx subshell oozie set dataset SubscriberSegment attribute doneFile _DONE",
  				"pmx subshell oozie set dataset SubscriberSegment attribute outputOffset 0",
  				"pmx subshell oozie set dataset SubscriberSegment attribute path /data/output/Segments/%Y/%M",
  				"pmx subshell oozie set dataset SubscriberSegment attribute startTime $timeDSet",
				"pmx subshell oozie set dataset SubscriberSegment attribute pathType hdfs",


				#"pmx subshell oozie set job CleanupLogs action CleanupLogAction attribute cleanupOffset 1",
				"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupOffset $$prop{job}{CleanupAtlas}{action}{CleanupAction}{attribute}{cleanupOffset}",
				#"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets $ExporterSrcDataset",
				#"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets SubcrBytes_$src",
				"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets SubscriberSegment",
				# Following added for 3.0rc3 #
				"pmx subshell oozie set job CleanupAtlas action CleanupAction attribute cleanupDatasets SubscriberSegmentMPH"
				);


			}

	chomp @cmds;
        return @cmds;
}


#sub ssh {
#
#        my $self=shift;
#        my $prop=shift;
#        my @cmds=("ssh client global host-key-check no");
#	$usernames=$$prop{key};
#	foreach my $user (keys %$usernames) {
#        	push(@cmds,
#				"ssh client user $user identity $$prop{key}{$user} generate"
#			);
#	}
#	
#	chomp @cmds;
#	return @cmds;
#	
#}




1;

