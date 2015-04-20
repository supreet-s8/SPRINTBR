package BR33;

use lib "./";
use Data::Dumper;
# $build=Atlas;
# $version=4.0.1VISP;

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

sub shell {

	my $self=shift;
	my $prop=shift;
	
	my @cmds=();
	foreach (sort {$a cmp $b} keys %{$prop->{commands}}) {

		push (@cmds, "_exec $prop->{commands}->{$_}");
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
#sub ip {
#	my $self=shift;
#	my $prop=shift;
#	my @cmds=();
#	my $enable=$$prop{'map-hostname'};
#	my $hosts=$$prop{host};
#	if ($enable eq 'yes') {
#		push(@cmds,"ip map-hostname");
#	} elsif ($enable eq 'no') {
#		push(@cmds,"no ip map-hostname");
#	}
#	foreach my $host (keys %$hosts) {
#		push(@cmds,"ip host $host $$hosts{$host}");
#	}
#
#	my $cmd="banner login \"WARNING NOTICE This system is for the use of authorized users only. Individuals using this system without authority, or in excess of their authority, are subject to having all of their activities on this system monitored and recorded by system personnel. In the course of monitoring individuals improperly using this system, or in the course of system maintenance, the activities of authorized users may also be monitored. Anyone using this system expressly consents to such monitoring and is advised that if such monitoring reveals possible evidence of criminal activity, system personnel may provide the evidence of such monitoring to law enforcement officials.\"";
#
#		push(@cmds,"hostname $$prop{hostname}",
#			   #"ip name-server $$prop{'name-server'}",
#			   #"ip default-gateway $$prop{'default-gateway'}",
#			   "no web enable",
#			   "no web http enable",
#			   "no web https enable",
#			   "no telnet-server enable",
#			   "no virt enable",			   
#			   "$cmd"
#		);
#		
#		
#	push (@cmds,
#
#		"ip filter chain FORWARD clear",
#		"ip filter chain INPUT clear",
#		"ip filter chain OUTPUT clear",
#		"ip filter chain INPUT policy ACCEPT",
#		"ip filter chain INPUT rule append tail target ACCEPT dup-delete in-intf lo",
#
#	);
#	
#	my $filter=$$prop{filter}{input}{accept};
#		foreach my $source (keys %$filter) {
#		push (@cmds, 	"ip filter chain INPUT rule append tail target ACCEPT protocol udp dest-port 5353 source-addr $$filter{$source} /32",
#				"ip filter chain INPUT rule append tail target ACCEPT dup-delete source-addr $$filter{$source} /32 dest-port 8080 protocol tcp"
#				);
#		
#	}		
#
#	my $port=$$prop{filter}{port}{accept};
#		foreach my $sourceP (keys %$port) {
#                push (@cmds, 	"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50060 source-addr $$port{$sourceP} /32",
#				"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50071 source-addr $$port{$sourceP} /32",
#				"ip filter chain INPUT rule append tail target ACCEPT protocol tcp dest-port 50076 source-addr $$port{$sourceP} /32"
#			);
#        }
#
#
#	push (@cmds,	
#		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
#		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
#		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
#		"ip filter chain INPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",
#
#		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 13 icmp-code 0",
#		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 14 icmp-code 0",
#		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 17 icmp-code 0",
#		"ip filter chain OUTPUT rule append tail target ACCEPT protocol icmp icmp-type 18 icmp-code 0",	      
#
#		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 13",
#		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 14",
#		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 17",
#		"ip filter chain OUTPUT rule append tail target DROP protocol icmp icmp-type 18",
#
#		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 13",
#		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 14",
#		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 17",
#		"ip filter chain INPUT rule append tail target DROP protocol icmp icmp-type 18",
#
## Disabled for now --
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50030",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50060",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50070",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50071",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50076",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50075",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 50090",
#		"ip filter chain INPUT rule append tail target DROP protocol udp dest-port 5353",
#		"ip filter chain INPUT rule append tail target DROP protocol tcp dest-port 8080",
#		"ip filter enable", 
#	      
#	);
#
#	chomp @cmds;
#	return @cmds;	
#	
#}
#


# Provide in a hash reference of the users and their properties.
sub user {

	my $self=shift;
	my $prop=shift;
	my @cmds=();
	my @cmd=();
	foreach my $user (keys %$prop) {
		my $password="";
		my $flag="";
		if($$prop{$user}{password}{0}) {
		$password=$$prop{$user}{password}{0};
		$flag="0";
		} elsif($$prop{$user}{password}{7}) {
		$password=$$prop{$user}{password}{7};
		$flag="7";
		} elsif($$prop{$user}{password}) {
		$password=$$prop{$user}{password};
		}
		my $status=$$prop{$user}{status};
		my $capability=undef;
		$capability=$$prop{$user}{capability};
		if ($status eq 'disable') {
			@cmd=("username $user disable");
		} else {
			@cmd=(	"no username $user disable",
				"username $user password $flag $password",
			     );
		}
		if (defined $capability) {
			push(@cmd,"username $user capability $capability");
		}
		push(@cmds,@cmd);
	}
	push (@cmds, "aaa authentication attempts lockout max-fail 3");	
	chomp @cmds;
	return @cmds;
} 


# Provide in the collector properties hash reference

sub collector {
	my $self=shift;
        my $prop=shift;
        my @cmds=();
	#my $count=0;

	@cmds=("collector add-instance 10","collector modify-instance 10 add-adaptor netflow");

	foreach my $router (keys %$prop) {

		push (@cmds,

				"collector modify-instance 10 modify-adaptor netflow add-port $prop->{$router}->{'port'}",
				"collector modify-instance 10 modify-adaptor netflow modify-port $prop->{$router}->{'port'} adapter-profile none",
				"collector modify-instance 10 modify-adaptor netflow modify-port $prop->{$router}->{'port'} filter-sourceIP disable",
				"collector modify-instance 10 modify-adaptor netflow modify-port $prop->{$router}->{'port'} router-name $router",
				"collector modify-instance 10 modify-adaptor netflow modify-port $prop->{$router}->{'port'} socket-IP 0.0.0.0"
		     );

	}

	push(@cmds,
			"collector modify-instance 10 modify-adaptor netflow backup-file-system hostname 127.0.0.1",
			"collector modify-instance 10 modify-adaptor netflow backup-file-system port 9000",
			"collector modify-instance 10 modify-adaptor netflow backup-file-system user admin",
			"collector modify-instance 10 modify-adaptor netflow bin-size 300",
			"collector modify-instance 10 modify-adaptor netflow drop-alarm-clear-interval 1",
			"collector modify-instance 10 modify-adaptor netflow drop-alarm-raise-interval 1",
			"collector modify-instance 10 modify-adaptor netflow drop-alarm-threshold 10",
			"collector modify-instance 10 modify-adaptor netflow file-format binCompactCompression",
			"collector modify-instance 10 modify-adaptor netflow file-system hdfs-seq-file",
			"collector modify-instance 10 modify-adaptor netflow prorate enable",
			"collector modify-instance 10 modify-adaptor netflow num-bins 4",
			"collector modify-instance 10 modify-adaptor netflow output-directory /data/collector/netflow/%y/%m/%d/%h/%mi/br.",
			"collector modify-instance 10 modify-adaptor netflow stack-log-level 0",
			"collector modify-instance 10 modify-adaptor netflow timeout 10",
			"collector modify-instance 10 modify-adaptor netflow auto-bin-slide disable",
			"pm liveness grace-period 600",
			"pm process collector launch auto",
			"pm process collector launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar:/opt/tms/java/MemSerializer.jar",
			"pm process collector launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib",
			"pm process collector launch environment set LD_PRELOAD /usr/lib64/libjemalloc.so",
			"pm process collector launch environment set LIBHDFS_OPTS \"-Xmx8192m\" ",
			"pm process collector launch relaunch auto",
			"pm process collector launch params 1 -i",
			"pm process collector launch params 2 10",
			"pm process collector launch enable "
				);

# ----- Temporary placeholder to disable insta process in PNSA builds ------
# ---------- DONE ---------
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

sub insta {
	my $self=shift;
	my $prop=shift;
	my @cmds=();


	@cmds=(
			"configure terminal",
			"insta instance-id create 0",
			"insta instance 0 cubes-xml $prop->{'cube_xml_path'}",
			"insta instance 0 cubes-database $prop->{'dbname'}",
			"insta instance 0 service-port 11111",
			"insta instance 0 dataRetentionPeriod 180",
			"pm process insta launch environment set LD_LIBRARY_PATH /opt/hadoop/c++/Linux-amd64-64/lib:/usr/java/jre1.6.0_25/lib/amd64/server:/opt/tps/lib:/platform_latest/insta/lib",
			"pm process insta launch environment set CLASSPATH /opt/tms/java/classes:/opt/hadoop/conf:/opt/hadoop/hadoop-core-0.20.203.0.jar:/opt/hadoop/lib/commons-configuration-1.6.jar:/opt/hadoop/lib/commons-logging-1.1.1.jar:/opt/hadoop/lib/commons-lang-2.4.jar",
			"pm process insta launch auto",
			"pm process insta launch relaunch auto",
			"pm process insta launch enable",
				"insta adapters infinidb set install-mode multi-server-install",
		"insta adapters infinidb set module-install-type combined",
		"insta adapters infinidb username root",
		"insta adapters infinidb password \"\"",
		"insta adapters infinidb cluster-name $prop->{cluster}->{name}",
		"insta adapters infinidb set storage-type ext2",
		"insta adapters infinidb dbroot 1",
		"insta adapters infinidb dbroot 1 storage-location /dev/mapper/dbroot1",
		"insta adapters infinidb dbroot 2",
		"insta adapters infinidb dbroot 2 storage-location /dev/mapper/dbroot2",
		"insta adapters infinidb dbroot 3",
		"insta adapters infinidb dbroot 3 storage-location /dev/mapper/dbroot3",
		"insta adapters infinidb dbroot 4",
		"insta adapters infinidb dbroot 4 storage-location /dev/mapper/dbroot4",
		"insta adapters infinidb modulecount 2",
		"insta adapters infinidb ipaddr $prop->{self}->{ip}",
		"insta adapters infinidb hamgr $prop->{cluster}->{vip}",
		"insta adapters infinidb module 1",
		"insta adapters infinidb module 2",
		"insta adapters infinidb module 1 ip $prop->{ip}->{module1}",
		"insta adapters infinidb module 2 ip $prop->{ip}->{module2}",
		"insta ipc serviceport 55555",
		"insta infinidb install",
		"internal set modify - /nr/insta/instance/0/max_query_interval value uint32 2678400",
		"internal set modify - /nr/insta/connection_pool_size value uint16 32",
		"internal set modify - /nr/insta/instance/0/max_outstanding_query  value uint16 16",
		"internal set modify - /nr/insta/common/infinidb/config/querypoolsize value uint16 8",
		"write memory",
		"pm process insta restart",
		"pmx register pgsql",
		"tps pgsql dbroot $prop->{pgsqlDir}",
		"tps pgsql mode external",
		"tps pgsql restart",
	      );

	foreach my $id (sort (keys %{$prop->{'wwid'}})) {
		push ( @cmds,
			"mpio multipaths alias dbroot$id wwid $prop->{'wwid'}->{$id}",
			);
	}

	push ( @cmds,
			"internal set modify - /nr/insta/connection_pool_size value uint16 32",
			"internal set modify - /nr/insta/instance/0/max_outstanding_query  value uint16 16",
			"internal set modify - /nr/insta/common/infinidb/config/querypoolsize value uint16 8",
			"pm process insta restart",
	      );

#For insta Backup

	foreach my $seq (sort (keys %{$prop->{'backupdbroot'}})) {
		push ( @cmds,
				"mpio multipaths alias backupdbroot1 wwid $prop->{'backupdbroot'}->{$seq}->{wwid}",
				"tps fs backupdbroot$seq uuid $prop->{'backupdbroot'}->{$seq}->{uuid}",
				"tps fs backupdbroot$seq wwid $prop->{'backupdbroot'}->{$seq}->{wwid}",
				"tps fs backupdbroot$seq mount-point $prop->{'backupdbroot'}->{$seq}->{mount_point}",
				"tps fs backupdbroot$seq mount-option mount-if-master",

			);
	}
		push ( @cmds,
			"write memory"
			);


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
		"internal set create - /tps/process/hadoop/attribute/mapred.child.java.opts/value value string \"\-Xmx4096m \-verbose\:gc \-XX\:\+PrintGCDetails \-XX\:\+PrintGCDateStamps\"",
		"pmx set backup_hdfs namenode UNINIT"
	);

	foreach my $client (split(/,/,$prop->{clients}->{ip})) {
		# Add the ICN IP Address of each Collector node as a client to the HDFS service
		my $cmd="pmx set hadoop client $client";
		push(@cmds,$cmd);
	}

	foreach my $slave (split(/,/,$prop->{slaves}->{ip})) {
		# Add the ICN IP Address of each Collector node as a client to the HDFS service
		my $cmd="pmx set hadoop slave $slave";
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

sub rge {
	my $self=shift;
	my $prop=shift;
	my $conf = "rubix modify-app rge modify-instance 0 set adv-attribute tomcatClusterInfo value \"";
	
	my @a = ("rubix" , "rge");
	foreach (@a){

		foreach my $ip ( (split (/,/ , ($prop->{ips}->{$_}))) ){
		next if ($ip =~ m/^$prop->{self}->{ip}$/);
		$conf .= "<Member className=\\\"org.apache.catalina.tribes.membership.StaticMember\\\" port=\\\"$prop->{port}->{$_}\\\" host=\\\"$ip\\\" uniqueId=\\\"{1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1}\\\"\/>";

		}
	}

	push(@cmds,
			"$conf\"",
			"httpd sla-ip 0.0.0.0",
			"httpd expose-sla-log true",
			"httpd sla-port 443",
                        "httpd add-cert-file  $prop->{CertificatePath}",
                        "httpd add-reverse-proxy /",
			"httpd add-reverse-proxy rubixbr",
			"httpd add-reverse-proxy rgebr",
			"httpd modify-reverse-proxy / address https://$prop->{hostname}->{rge}$prop->{cookiedomain}:9443",
			"httpd modify-reverse-proxy / url /",
			"httpd modify-reverse-proxy rubixbr address https://$prop->{hostname}->{rubix}$prop->{cookiedomain}:8443",
			"httpd modify-reverse-proxy rubixbr url /rubixbr",
			"httpd modify-reverse-proxy rgebr address https://$prop->{hostname}->{rge}$prop->{cookiedomain}:9443",
			"httpd modify-reverse-proxy rgebr url /rgebr",
			"httpd SSLCipherSuite HIGH",
			"httpd SSLProtocol +TLSv1",
			"web https 13443 port",
			"rubix add-app rge config-xml /opt/tms/rge-bizreflex3.3/WEB-INF/classes/rgeConfiguration.xml",
			"rubix modify-app rge add-instance 0",
			"rubix modify-app rge modify-instance 0 set adv-attribute serverPort value 9005",
			"rubix modify-app rge modify-instance 0 set adv-attribute connectorPort value 9080",
			"rubix modify-app rge modify-instance 0 set adv-attribute connectorPortAJP value 9009",
			"rubix modify-app rge modify-instance 0 set attribute redirectPort value 9443",
			"rubix modify-app rge modify-instance 0 set attribute ipAddress value $prop->{self}->{ip}",
			"rubix modify-app rge modify-instance 0 set adv-attribute channelReceiverPort value 4010",
			"rubix modify-app rge modify-instance 0 set attribute docBase value /data/instances/rge/0/app",
			"rubix modify-app rge modify-instance 0 set adv-attribute sessionCookieDomain value $prop->{cookiedomain}",
			"rubix modify-app rge modify-instance 0 set adv-attribute JMXPORT value 9089",
			"rubix modify-app rge modify-instance 0 set adv-attribute tomcatInstanceMaxSize value 10g",
			"rubix modify-app rge modify-instance 0 set adv-attribute initialJavaHeapSize value 10g",
			"rubix modify-app rge modify-instance 0 set attribute MAXPERMSIZE value 512m",
			"rubix modify-app rge modify-instance 0 set attribute runMode value insta",
			"rubix modify-app rge modify-instance 0 set attribute SKIPUPDATECHECK value true",
			"rubix modify-app rge modify-instance 0 set attribute JMXAUTHENTICATE value false",
			"rubix modify-app rge modify-instance 0 set attribute JMXSSL value false",
			"rubix modify-app rge set attribute applicationPath value /opt/tms/rge-bizreflex3.3",
			"rubix modify-app rge modify-instance 0 set attribute rgeumDBVersion value 0.0",
			"rubix modify-app rge modify-instance 0 set attribute rgeapplyServicePermission value false",
			"rubix modify-app rge modify-instance 0 set attribute rgesolutionDBVersion value 0.0",
			"rubix modify-app rge modify-instance 0 set attribute rgestaticSecurityManagerEnabledShiroEnv value true",
			"rubix modify-app rge modify-instance 0 set attribute RGEDEFAULTRUBIXURL value https://$prop->{hostname}->{rubix}$prop->{cookiedomain}/rubixbr",
			"rubix modify-app rge modify-instance 0 set attribute RGEDEFAULTRGEURL value https://$prop->{hostname}->{rge}$prop->{cookiedomain}/rgebr",
			"rubix modify-app rge modify-instance 0 set attribute rgerubixNumInitialMembers value 2",
			"rubix modify-app rge modify-instance 0 set attribute rgerubixPortRange value 5",
			"rubix modify-app rge modify-instance 0 set attribute rgedeployedCustomerName value $prop->{customerName} ",
			"rubix modify-app rge modify-instance 0 set attribute rgekeyStore value /data/instances/rge/0/app/WEB-INF/classes/keystore",
			"rubix modify-app rge modify-instance 0 set attribute rgeiReportGenDir value /data/rge/",
			"rubix modify-app rge modify-instance 0 set attribute rgesuperkey value Admin\@123",
			"rubix modify-app rge modify-instance 0 set attribute rgereportDirectory value /data/instances/rge/0/app/WEB-INF/classes",
			"rubix modify-app rge modify-instance 0 set attribute RGESLAHOME value /data/instances/rge/0/sla_logs",
			"rubix modify-app rge modify-instance 0 set attribute rgepojoNameForCustomTablename value IdNameMap;Filter;EntityNameToAsPRIRule;AsProspectRule;AsBlacklistRule;BRConfigurationData;",
			"rubix modify-app rge modify-instance 0 set attribute rgedialect value com.guavus.rubix.hibernate.dialect.PostgreSQLCustomDialect",
			"rubix modify-app rge modify-instance 0 set attribute rgeconnectionProviderClass value org.hibernate.connection.C3P0ConnectionProvider",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateConnectionUserName value rubix",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateConnectionPassword value rubix\@123",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateConnectionUrl value jdbc:postgresql://$prop->{insta}->{ip}:5432/$prop->{db}->{rge}",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateConnectionDriverClass value org.postgresql.Driver",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateCacheInfinispanCfg value cluster-infinispan-configs.xml",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateQueryCache value true",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateCacheRegionFactoryClass value org.hibernate.cache.infinispan.InfinispanRegionFactory",
			"rubix modify-app rge modify-instance 0 set attribute rgehibernateSecondLevelCache value true",
			"rubix modify-app rge modify-instance 0 set attribute rgecurrentSessionContextClass value thread",
			"rubix modify-app rge modify-instance 0 set attribute rgedistributedConnectionPassword value rubix\@123",
			"rubix modify-app rge modify-instance 0 set attribute rgedistributedConnectionUserName value rubix",
			"rubix modify-app rge modify-instance 0 set attribute rgedistributedConnectionUrl value jdbc:postgresql://$prop->{insta}->{ip}:5432/$prop->{db}->{rubix}",
			"rubix modify-app rge modify-instance 0 set attribute rgedistributedConnectionDriverClass value org.postgresql.Driver",
			"rubix modify-app rge modify-instance 0 set attribute rgeinfinispanJgroupConfigFile value rubix-jgroups.xml",
			"rubix modify-app rge modify-instance 0 set attribute RgeL2CacheClusterName value rge-cluster-infinipan-new",
			"rubix modify-app rge modify-instance 0 set attribute rgemapImageDirectory value /data/instances/rge/0/app/WEB-INF/classes/reports/map",
			"rubix modify-app rge modify-instance 0 set attribute rgerubixInitialHost value $prop->{ipsPort}->{Rubix} ",
			"rubix modify-app rge modify-instance 0 set attribute rgemailsupport value $prop->{email} ",
			"rubix modify-app rge modify-instance 0 set attribute rgecentralTimeZone value $prop->{timezone} ",
			"rubix modify-app rge enable",
			"rubix modify-app rge modify-instance 0 enable",
			"configuration write",
			"pm process httpd restart",
			"pm process rubix restart",
		);

	chomp @cmds;
	return @cmds;
}

sub rubixui {
	my $self=shift;
	my $prop=shift;
	my $conf = "rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute tomcatClusterInfo value \"";

#	foreach my $ip ( (split (/,/ , ($prop->{ips}->{rubix}))) , (split (/,/ , ($prop->{ips}->{rge}))) ){
#		next if ($ip =~ m/^$prop->{self}->{ip}$/);
#		$conf .= "<Member className=\\\"org.apache.catalina.tribes.membership.StaticMember\\\" port=\\\"$prop->{port}\\\" host=\\\"$ip\\\" uniqueId=\\\"{1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1}\\\"\/>";
#	}
	my @a = ("rubix" , "rge");
	foreach (@a){

		foreach my $ip ( (split (/,/ , ($prop->{ips}->{$_}))) ){
		next if ($ip =~ m/^$prop->{self}->{ip}$/);
		$conf .= "<Member className=\\\"org.apache.catalina.tribes.membership.StaticMember\\\" port=\\\"$prop->{port}->{$_}\\\" host=\\\"$ip\\\" uniqueId=\\\"{1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1}\\\"\/>";

		}
	}
	push(@cmds,
			"$conf\"",
			"rubix delete-app bizreflex_rubix",
			"rubix add-app bizreflex_rubix config-xml /opt/tms/bizreflex-bizreflex3.3/WEB-INF/classes/rubixConfiguration.xml",
			"rubix modify-app bizreflex_rubix add-instance 0",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute JMXPORT value \"8089\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute SCHEDULERMAXSEGMENTDURATION value \"86400\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute applyServicePermission value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute blazedsLoggingLevel value \"INFO\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute c3p0LoggingLevel value \"INFO\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute cacheDiskstore value \"$prop->{path}\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute channelReceiverPort value \"4010\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute configFileProperty value \"/data/configs/EntityConfig/\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute connectorPort value \"8080\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute connectorPortAJP value \"8009\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute customNamingStrategyEnabledHibernate value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute flexLoggingLevel value \"INFO\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute initialJavaHeapSize value \"$prop->{heap_size}\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute isCaseInsensitive value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute jgroupsLoggingLevel value \"INFO\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute keyStoreName value \"/sso.jks\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute maxLogHistory value \"30\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute moduleTimeDumpDelta value \"60\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute nonInteractionCubesPrefetchOnly value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute percentileOnlyAsBased value \"false\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute pojoNameForCustomTablename value \"IdNameMap;Filter;EntityNameToAsPRIRule;AsProspectRule;AsBlacklistRule;BRConfigurationData;\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute pojoNamesToUseHibernateSequence value \"\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute promptChangePasswd value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute prospectBlacklistDbpollInterval value \"30000\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute protectedFileExtension value \"swf\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute reloadPolicyRetryInterval value \"3600\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute reportRubixNode value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute requestResponseLoggingLevel value \"INFO\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute rootLoggingLevel value \"INFO\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute samlValidator value \"com.guavus.rubix.user.management.sso.SAML20Validator\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute schedulerStartDelay value \"260\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute serverPort value \"8005\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute solutionDBVersion value \"0.0\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute solutionName value \"$prop->{sol_name}\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute staticSecurityManagerEnabledShiroEnv value \"false\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute tomcatClusterName value \"tomcat-cluster\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute tomcatInstanceMaxSize value \"$prop->{memorary}\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute umDBVersion value \"0.0\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute unRestrictedResources value \"main.swf\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute JMXAUTHENTICATE value \"false\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute JMXSSL value \"false\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute MAXPERMSIZE value \"512m\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute SKIPUPDATECHECK value \"true\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute docBase value \"/data/instances/bizreflex_rubix/0/app\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute nodeUniqueIdentifier value \"$prop->{hostname}->{node}\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute redirectPort value \"8443\"",
			"rubix modify-app bizreflex_rubix modify-instance 0 set attribute runMode value \"insta\"",
			"rubix modify-app bizreflex_rubix set adv-attribute DEFAULTUNCOMPRESSEDSUBSCRIBERCOUNT value \"16\"",
			"rubix modify-app bizreflex_rubix set adv-attribute ForceRunInSingleMode value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute INSTACOMBOPOINTS value \"744\"",
			"rubix modify-app bizreflex_rubix set adv-attribute JgroupsConfigfile value \"rubix-jgroups.xml\"",
			"rubix modify-app bizreflex_rubix set adv-attribute L2CacheClusterName value \"Bizreflex-Cluster-Infinispan\"",
			"rubix modify-app bizreflex_rubix set adv-attribute MemoryRetentionBuffer value \"0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute NoOfDecimalPlacesForRoundingInStats value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute RRCacheEvictionCount value \"5000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute RunSchedulerOnlyOnCoordinator value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute SCHEDULERVARIABLEGRANULARITYMAP value \"1d:217;7d:31;1M:6\"",
			"rubix modify-app bizreflex_rubix set adv-attribute VariableRetentionMap value \"5m:51840;1h:1488;1d:186;7d:0;1M:0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterLifo value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterMaxIdle value \"-1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterMaxWait value \"0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterMaxactive value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterMinEvictableIdleTimeMillis value \"0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterMinIdle value \"-1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterNumTestsPerEvictionRun value \"10\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterSoftMinEvictableIdleTimeMillis value \"0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterTestOnBorrow value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterTestOnReturn value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterTestWhileIdle value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterTimeBetweenEvictionRunsMillis value \"1000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute adapterWhenExhaustedAction value \"1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute aggregateEvictionDiskThresholdCount value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute aggregateEvictionThresholdCount value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute aggregateFromTimeseriesData value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute aggregateThreadPoolSize value \"16\"",
			"rubix modify-app bizreflex_rubix set adv-attribute allowedDimensionSetDiff value \"0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute appendCacheIdentifierPopulatingTimeseries value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute binClassToBinSrcChckIntrvl value \"300\"",
			"rubix modify-app bizreflex_rubix set adv-attribute byteBufferTimeseriesEvictionDiskThresholdCount value \"320\"",
			"rubix modify-app bizreflex_rubix set adv-attribute byteBufferTimeseriesEvictionThresholdCount value \"360\"",
			"rubix modify-app bizreflex_rubix set adv-attribute cacheOverflowToDisk value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute cachePersistToDisk value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute cachePreloadEnable value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute checkSearchCubeTimeGran value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute clusterCheckCount value \"60\"",
			"rubix modify-app bizreflex_rubix set adv-attribute clusterCheckInterval value \"2000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute clusterRequestTimeout value \"1800000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute clusterVirtualNodesCount value \"100\"",
			"rubix modify-app bizreflex_rubix set adv-attribute connectionProviderClass value \"org.hibernate.connection.C3P0ConnectionProvider\"",
			"rubix modify-app bizreflex_rubix set adv-attribute currentSessionContextClass value \"thread\"",
			"rubix modify-app bizreflex_rubix set adv-attribute dayLevelCacheDuration value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute defaultAggregationInterval value \"-1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute defaultBinSource value \"\"",
			"rubix modify-app bizreflex_rubix set adv-attribute defaultSyncPolicy value \"com.guavus.rubix.cache.sync.DefaultSyncPolicy\"",
			"rubix modify-app bizreflex_rubix set adv-attribute dialect value \"org.hibernate.dialect.HSQLDialect\"",
			"rubix modify-app bizreflex_rubix set adv-attribute diskPersistGranularityRetentionCombinePoint value \"5m:288;1h:24;3h:8;1d:30;7d:4;1M:1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute diskRetentionPeriod value \"5m:62496;1h:1488;1d:217;7d:31;1M:7\"",
			"rubix modify-app bizreflex_rubix set adv-attribute distributedConnectionDriverClass value \"org.postgresql.Driver\"",
			"rubix modify-app bizreflex_rubix set adv-attribute distributedConnectionUrl value \"jdbc:postgresql://$prop->{insta}->{ip}:5432/$prop->{dbname}\"",
			"rubix modify-app bizreflex_rubix set adv-attribute distributedDialect value \"com.guavus.rubix.hibernate.dialect.PostgreSQLCustomDialect\"",
			"rubix modify-app bizreflex_rubix set adv-attribute distributionResponseDelayInterval value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute enableFilterCachingInRubixCache value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute gaugeCubeGranularity value \"300\"",
			"rubix modify-app bizreflex_rubix set adv-attribute geometricProgressionPolicyCommonRatio value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute haJDBCBalancer value \"round-robin\"",
			"rubix modify-app bizreflex_rubix set adv-attribute haJDBCDialect value \"HSQLDB\"",
			"rubix modify-app bizreflex_rubix set adv-attribute haJDBCMetaDataCache value \"none\"",
			"rubix modify-app bizreflex_rubix set adv-attribute haJDBCTransactionMode value \"serial\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hasRubixCubesWithNoMeasures value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateCacheInfinispanCfg value \"cluster-infinispan-configs.xml\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateCacheRegionFactoryClass value \"org.hibernate.cache.infinispan.InfinispanRegionFactory\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateConnectionDriverClass value \"org.hsqldb.jdbcDriver\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateConnectionUrl value \"jdbc:hsqldb:mem:rubix\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateQueryCache value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateRubixFile value \"um.sql\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateSecondLevelCache value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hibernateSolutionFile value \"bizreflex.sql\"",
			"rubix modify-app bizreflex_rubix set adv-attribute hourLevelCacheDuration value \"7\"",
			"rubix modify-app bizreflex_rubix set adv-attribute ignrdDimensionListFile value \"/ignoredDimensionList.txt\"",
			"rubix modify-app bizreflex_rubix set adv-attribute inMemHibernateCacheProviderClass value \"org.hibernate.cache.NoCacheProvider\"",
			"rubix modify-app bizreflex_rubix set adv-attribute inMemHibernateSecondLevelCache value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute infinispanJgroupConfigFile value \"rubix-jgroups.xml\"",
			"rubix modify-app bizreflex_rubix set adv-attribute instaResponseTimeout value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute isInstaQueryRedirectEnabled value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute lastModified value \"43200\"",
			"rubix modify-app bizreflex_rubix set adv-attribute lastmodified value \"\"",
			"rubix modify-app bizreflex_rubix set adv-attribute mailErrCheckInterval value \"3600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxAggregateInterval value \"2678400\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxDimSetAsFilter value \"100\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxFilterCombinationToBeCached value \"10\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxFilterSizeToBeCached value \"2500\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxLength value \"10\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxSegmentsToSyncInThread value \"0\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxSyncTask value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute maxTimeSeriesInterval value \"2678400\"",
			"rubix modify-app bizreflex_rubix set adv-attribute minSubsbrCountDays value \"7\"",
			"rubix modify-app bizreflex_rubix set adv-attribute pointRubixCacheDefaultEvictionPolicy value \"com.guavus.rubix.cache.policy.PointRubixCacheVariableRetentionPolicy\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rangeCacheAllRanges value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rangeCacheEvictionDiskThresholdCount value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rangeCacheEvictionThresholdCount value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rangeRubixCacheDefaultEvictionPolicy value \"com.guavus.rubix.cache.policy.RangeRubixCacheVariableRetentionPolicy\"",
			"rubix modify-app bizreflex_rubix set adv-attribute reuseInstaConnection value \"false\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rgeUrl value \"$prop->{rgeURL}\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rootCAPath value \"root.crt\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rrCacheConcurrencyLevel value \"16\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rubixCacheDeserializingThread value \"10\"",
			"rubix modify-app bizreflex_rubix set adv-attribute rubixShellDiscardErrorMessage value \"Guavus Network Systems Netreflex Platform\"",
			"rubix modify-app bizreflex_rubix set adv-attribute ruleTimeGranularity value \"3600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerCheckInterval value \"300\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerExponentialBackoffFactor value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerInstaQueryfetchTaskNoOfRetries value \"6\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerInstaQueryfetchTaskRetryIntervalInMillis value \"600000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerLatestSETime value \"-1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerMaxReqInterval value \"86400\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerMinReqInterval value \"3600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerOldestSETime value \"-1\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerPolicy value \"com.guavus.rubix.scheduler.VariableGranularitySchedulerPolicy\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerQueryPrefetchRetryCnt value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerQueryPrefetchRetryIntrvl value \"600000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerSingleEntitiesCount value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerThreadPoolSize value \"4\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulerTimeGranCeilFloor value \"3600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute schedulervariableretentioncombinepoints value \"288\"",
			"rubix modify-app bizreflex_rubix set adv-attribute searchMinGapInterval value \"3600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute searchPollInterval value \"3600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute sessionCookieDomain value \".guavus.com\"",
			"rubix modify-app bizreflex_rubix set adv-attribute singleEntityDiskEvictionThresholdCount value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute singleEntityEvictionThresholdCount value \"5\"",
			"rubix modify-app bizreflex_rubix set adv-attribute sslModeForDBConnection value \"disable\"",
			"rubix modify-app bizreflex_rubix set adv-attribute subQueryCacheSizeLocalMode value \"10000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute subQueryLocalCacheConcurrencyLevel value \"16\"",
			"rubix modify-app bizreflex_rubix set adv-attribute syncManagerWaitShutdownTime value \"600\"",
			"rubix modify-app bizreflex_rubix set adv-attribute syncTaskScheduleInterval value \"300\"",
			"rubix modify-app bizreflex_rubix set adv-attribute syncUser value \"root\"",
			"rubix modify-app bizreflex_rubix set adv-attribute testEnableTrimByteBuffers value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute threadPoolSize value \"16\"",
			"rubix modify-app bizreflex_rubix set adv-attribute thriftKeepAlive value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute timeZone value \"$prop->{timezone}\"",
			"rubix modify-app bizreflex_rubix set adv-attribute timeseriesEvictionDiskThresholdCount value \"446400\"",
			"rubix modify-app bizreflex_rubix set adv-attribute timeseriesEvictionThresholdCount value \"446400\"",
			"rubix modify-app bizreflex_rubix set adv-attribute timeseriesLevelMap value \"1h:1448;1d:217\"",
			"rubix modify-app bizreflex_rubix set adv-attribute toppagesGrowthEnabled value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute toppagesTraffic95tileEnabled value \"true\"",
			"rubix modify-app bizreflex_rubix set adv-attribute treeRubixCacheDefaultEvictionPolicy value \"com.guavus.rubix.cache.policy.TreeRubixCacheVariableRetentionPolicy\"",
			"rubix modify-app bizreflex_rubix set adv-attribute uiExponentialBackoffFactor value \"2\"",
			"rubix modify-app bizreflex_rubix set adv-attribute uiInstaQueryfetchTaskNoOfRetries value \"3\"",
			"rubix modify-app bizreflex_rubix set adv-attribute uiInstaQueryfetchTaskRetryIntervalInMillis value \"60000\"",
			"rubix modify-app bizreflex_rubix set adv-attribute umJGroupsClusterName value \"tcp-sync\"",
			"rubix modify-app bizreflex_rubix set adv-attribute umJGroupsConfig value \"ha-jdbc-jgroups.xml\"",
			"rubix modify-app bizreflex_rubix set adv-attribute umJgroupsBindPort value \"7900\"",
			"rubix modify-app bizreflex_rubix set adv-attribute umJgroupsInitialHost value \"$prop->{ips1}->{rubix}\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute umJgroupsNumInitialMembers value \"1\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute umJgroupsPortRange value \"1\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute useBaseGran value \"false\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute useBinSourceApi value \"true\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute useIdNameNoReserveAPI value \"true\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute useRangeCache value \"false\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute useSubQueryCacheLocalMode value \"true\"",
                        "rubix modify-app bizreflex_rubix set adv-attribute userTimeZone value \"false\"",
                        "rubix modify-app bizreflex_rubix set attribute applicationPath value \"/opt/tms/bizreflex-bizreflex3.3\"",
                        "rubix modify-app bizreflex_rubix set attribute clusterName value \"BRRUB\"",
                        "rubix modify-app bizreflex_rubix set attribute clusterSize value \"6\"",
                        "rubix modify-app bizreflex_rubix set attribute cubeGenerator value \"com.guavus.rubix.bizreflex.rules.DistributedCubeGenerator\"",
                        "rubix modify-app bizreflex_rubix set attribute dataDir value \"data\"",
                        "rubix modify-app bizreflex_rubix set attribute datasourceAdapter value \"com.guavus.rubix.dao.OptimizedInstaAdapter\"",
                        "rubix modify-app bizreflex_rubix set attribute distributedConnectionUserName value \"rubix\"",
                        "rubix modify-app bizreflex_rubix set attribute hibernateConnectionUserName value \"sa\"",
                        "rubix modify-app bizreflex_rubix set attribute instaCubeDefinitionPath value \"/opt/tms/xml_schema/BizreflexCubeDefinition.xml\"",
                        "rubix modify-app bizreflex_rubix set attribute ipAddress value \"$prop->{selfip}\"",
                        "rubix modify-app bizreflex_rubix set attribute maxClusterMembers value \"$prop->{hostname}->{all}\"",
                        "rubix modify-app bizreflex_rubix set attribute maxClusterSize value \"6\"",
                        "rubix modify-app bizreflex_rubix set attribute minClusterSize value \"4\"",
                        "rubix modify-app bizreflex_rubix set attribute numOwners value \"3\"",
                        "rubix modify-app bizreflex_rubix set attribute numSegments value \"64\"",
                        "rubix modify-app bizreflex_rubix set attribute psHost value \"$prop->{insta}->{ip}\"",
                        "rubix modify-app bizreflex_rubix set attribute psPort value \"$prop->{insta}->{port}\"",
                        "rubix modify-app bizreflex_rubix set attribute resolver value \"com.guavus.rubix.bizreflex.BizReflexResolver\"",
                        "rubix modify-app bizreflex_rubix set attribute rubixNumInitialMembers value \"6\"",
                        "rubix modify-app bizreflex_rubix set attribute rubixInitialHost value \"$prop->{ips2}->{rubix}\"",
                        "rubix modify-app bizreflex_rubix set attribute rubixPortRange value \"1\"",
                        "rubix modify-app bizreflex_rubix set attribute scheduler value \"true\"",
                        "rubix modify-app bizreflex_rubix set attribute superUser value \"admin\"",
                        "rubix modify-app bizreflex_rubix enable",
                        "rubix modify-app bizreflex_rubix modify-instance 0 enable",
                        "rubix modify-app bizreflex_rubix set attribute hibernateConnectionPassword value \"\"",
                        "rubix modify-app bizreflex_rubix modify-instance 0 set adv-attribute keyStorePassword value sso123",
                        "rubix modify-app bizreflex_rubix set attribute distributedConnectionPassword value rubix\@123",
                        "rubix modify-app <app name> set adv-attribute mailHost value  \"$prop->{hostAddr}\"",
			"rubix modify-app <app name> set adv-attribute mailPort value  \"$prop->{hostPort}\"",
			"rubix modify-app <app name> set adv-attribute mailRecipients value  \"$prop->{recipAddr}\"",
			"rubix modify-app <app name> set adv-attribute mailSender value  \"$prop->{senderAddr}\"",
			"pm process rubix launch auto",
			"pm process rubix launch relaunch auto",
			"write memory"
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

		if ($host->{'selfip'}) {
			push(@cmds,"pmx set drbd selfip $$prop{self}{ip}");
		} else {
			push(@cmds, "pmx set drbd $host $$prop{$host}{hostname}",
					, "pmx set drbd $host"."ip $$prop{$host}{ip}");
		}
	}


# DRBD wait time
	push (@cmds,"pmx set drbd waittime 300");
	chomp @cmds;
	return @cmds;
}

sub samplicate {
	my $self=shift;
	my $prop=shift;
	my @cmds=(
			"pm process samplicate launch $prop->{'state'} ",
			"pm process samplicate launch auto",
			"pm process samplicate launch relaunch auto",
			"pm process samplicate path /opt/tms/bin/samplicate",
			"pm process samplicate launch params 1 -S",
			"pm process samplicate launch params 2 -p",
			"pm process samplicate launch params 3 $prop->{port}",
			"pm process samplicate launch params 4 -b",
			"pm process samplicate launch params 5 $prop->{socketBufferSize}",
			"pm process samplicate launch params 6 -c",
			"pm process samplicate launch params 7 /data/configs/samplicate.cfg",
			"write memory",
		 );

# Hostname and ICN IP address of first name node

	if ($prop->{'state'} eq "enable") {
		push(@cmds,"pm process samplicate restart");
	}
	chomp @cmds;
	return @cmds;
}

sub mp {

	my @cmds=(
			"internal set modify - /tps/process/hadoop/attribute/mapred.child.java.opts/value value string -Xmx7168m",
			"internal set modify - /tps/process/hadoop/attribute/mapred.min.split.size/value value string 268435456",
			"internal set modify - /tps/process/hadoop/attribute/mapred.reduce.tasks/value value string 10",
			"internal set modify - /tps/process/hadoop/attribute/mapred.tasktracker.map.tasks.maximum/value value string 10",
			"internal set modify - /tps/process/hadoop/attribute/mapred.tasktracker.reduce.tasks.maximum/value value string 10",
			"internal set modify - /tps/process/hadoop/attribute/mapred.jobtracker.taskScheduler/value value string org.apache.hadoop.mapred.JobQueueTaskScheduler",

		 );
	chomp @cmds;
	return @cmds;
}

# Provide in the reference of hash for SM section.
sub sm {
	my $self=shift;
	my $prop=shift;
	my @cmds=();

# Configure Storage on both Name Nodes
	@cmds=(
			"sm service create INSTA::BLOCKING:1",
			"sm service modify INSTA::BLOCKING:1 service-info insta-server-info1",
			"sm service-info create insta-server-info1",
			"sm service-info modify insta-server-info1 host $prop->{instaNode}->{vip}",
			"sm service-info modify insta-server-info1 port $prop->{instaNode}->{port}",
			"sm service-info modify insta-server-info1 service-type TCP_SOCKET"	
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
			"snmp-server host $prop->{'server'}->{'ip'} traps version 2c guavus ",          
			"snmp-server listen enable",
			"snmp-server location $prop->{'server'}->{'location'}",
			"snmp-server community $prop->{'server'}->{'community'} ro",
			"snmp-server traps community guavus",
			"snmp-server traps event HDFS-namenode-status",
			"snmp-server traps event collector-data-resume",
			"snmp-server traps event cpu-util-high",
			"snmp-server traps event cpu-util-ok",
			"snmp-server traps event disk-io-high",
			"snmp-server traps event disk-space-low",
			"snmp-server traps event disk-space-ok",
			"snmp-server traps event insta-adaptor-down",
			"snmp-server traps event interface-down",
			"snmp-server traps event interface-up",
			"snmp-server traps event memusage-high",
			"snmp-server traps event netusage-high",
			"snmp-server traps event no-collector-data",
			"snmp-server traps event paging-high",
			"snmp-server traps event paging-ok",
			"snmp-server traps event process-crash",
			"snmp-server traps event process-exit",
			"snmp-server traps event process-relaunched",
			"snmp-server traps event test-trap",
			"snmp-server traps event unexpected-shutdown",
			"stats alarm disk_io enable",
			"stats alarm intf_util enable",
			"stats alarm memory_pct_used enable",
			"snmp-server user admin v3 enable",
			"wr mem"
	);

	chomp @cmds;
	return @cmds;
}



# Provide reference of a hash for Oozie section properties
sub oozie {
	my $self=shift;
	my $prop=shift;
	my @cmds=();
	my $Dset=`date "+%Y-%m-%dT%H:00Z"`;
	push (@cmds,	"pmx set oozie namenode $$prop{namenode}{hostname}",
			"pmx set oozie oozieServer $$prop{namenode}{vip}",
			"pmx set oozie sshHost 127.0.0.1",
			"pmx set oozie snapshotPath /data/snapshots",
			&mp());


	push (	@cmds,	
			"pmx subshell oozie add dataset ds_rollup_in",
			"pmx subshell oozie set dataset ds_rollup_in attribute startOffset 288",
			"pmx subshell oozie set dataset ds_rollup_in attribute frequency 5",
			"pmx subshell oozie set dataset ds_rollup_in attribute endOffset 1",
			"pmx subshell oozie set dataset ds_rollup_in attribute outputOffset 0",
			"pmx subshell oozie set dataset ds_rollup_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_rollup_in attribute path /data/collector/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset ds_rollup_in attribute startTime $Dset",
			"pmx subshell oozie set dataset ds_rollup_in attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_rollup_in attribute frequencyUnit minute",
			"pmx subshell oozie add dataset ds_rollup_out",
			"pmx subshell oozie set dataset ds_rollup_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_rollup_out attribute frequency 1440",
			"pmx subshell oozie set dataset ds_rollup_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_rollup_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_rollup_out attribute path /data/BR_OUT/TempRollUpJob/%Y/%M/%D/",
			"pmx subshell oozie set dataset ds_rollup_out attribute startTime $Dset",
			"pmx subshell oozie set dataset ds_rollup_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_rollup_out attribute frequencyUnit minute",
			"pmx subshell oozie add dataset temp_potAs_out",
			"pmx subshell oozie set dataset temp_potAs_out attribute startOffset 1",
			"pmx subshell oozie set dataset temp_potAs_out attribute frequency 1440",
			"pmx subshell oozie set dataset temp_potAs_out attribute endOffset 1",
			"pmx subshell oozie set dataset temp_potAs_out attribute outputOffset 1",
			"pmx subshell oozie set dataset temp_potAs_out attribute path /data/BR_OUT/TempPotAsJob/%Y/%M/%D/",
			"pmx subshell oozie set dataset temp_potAs_out attribute pathType hdfs",
			"pmx subshell oozie set dataset temp_potAs_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset temp_potAs_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_base_in",
			"pmx subshell oozie set dataset ds_base_in attribute startOffset 12",
			"pmx subshell oozie set dataset ds_base_in attribute frequency 5 ",
			"pmx subshell oozie set dataset ds_base_in attribute endOffset 1",
			"pmx subshell oozie set dataset ds_base_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_base_in attribute outputOffset 0",
			"pmx subshell oozie set dataset ds_base_in attribute path /data/collector/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset ds_base_in attribute startTime $Dset",
			"pmx subshell oozie set dataset ds_base_in attribute pathType hdfs   ",
			"pmx subshell oozie set dataset ds_base_in attribute frequencyUnit minute   ",
			"pmx subshell oozie add dataset ds_base_out",
			"pmx subshell oozie set dataset ds_base_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_base_out attribute frequency 60",
			"pmx subshell oozie set dataset ds_base_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_base_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_base_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_base_out attribute path /data/BR_OUT/MasterJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset ds_base_out attribute pathType hdfs   ",
			"pmx subshell oozie set dataset ds_base_out attribute frequencyUnit minute   ",
			"pmx subshell oozie set dataset ds_base_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_prefix_out",
			"pmx subshell oozie set dataset ds_prefix_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_prefix_out attribute frequency 60  ",
			"pmx subshell oozie set dataset ds_prefix_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_prefix_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_prefix_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_prefix_out attribute path /data/BR_OUT/PrefixJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset ds_prefix_out attribute pathType hdfs  ",
			"pmx subshell oozie set dataset ds_prefix_out attribute frequencyUnit minute  ",
			"pmx subshell oozie set dataset ds_prefix_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_bizrl_ds_in",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute startOffset 1",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute frequency 60",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute endOffset 1",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute path /data/BR_OUT/MasterJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute startTime $Dset",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_bizrl_ds_in attribute frequencyUnit minute",
			"pmx subshell oozie add dataset ds_bizrl_ds_out",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute frequency 60",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute path /data/BR_OUT/BizRulesJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset ds_bizrl_ds_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_topAs_ds_out",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute frequency 60",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute path /data/BR_OUT/TopAsJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset ds_topAs_ds_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_topInt_ds_out",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute frequency 60",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute path /data/BR_OUT/TopIntJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset ds_topInt_ds_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_ds_base_out",
			"pmx subshell oozie set dataset exp_ds_base_out attribute startOffset 1",
			"pmx subshell oozie set dataset exp_ds_base_out attribute frequency 60",
			"pmx subshell oozie set dataset exp_ds_base_out attribute endOffset 1",
			"pmx subshell oozie set dataset exp_ds_base_out attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_ds_base_out attribute path /data/BR_OUT/MasterJob/%Y/%M/%D/%H/X.MAPREDUCE.0.2",
			"pmx subshell oozie set dataset exp_ds_base_out attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_ds_base_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_ds_base_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_ds_prefix_out",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute startOffset 1",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute frequency 60",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute endOffset 1",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute path /data/BR_OUT/PrefixJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_ds_prefix_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_ds_bizr_out",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute startOffset 1",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute frequency 60",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute endOffset 1",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute path /data/BR_OUT/BizRulesJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_ds_bizr_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_ds_topAs_out",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute startOffset 1",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute frequency 60",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute endOffset 1",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute path /data/BR_OUT/TopAsJob/%Y/%M/%D/%H/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_ds_topAs_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_ds_topInt_out",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute startOffset 1",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute frequency 60",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute endOffset 1",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute path /data/BR_OUT/TopIntJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_ds_topInt_out attribute startTime $Dset",
			"pmx subshell oozie add dataset bizrl_agg1d_in",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute startOffset 24",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute frequency 60",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute path /data/BR_OUT/BizRulesJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute startTime $Dset",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1d_in attribute frequencyUnit minute",
			"pmx subshell oozie add dataset bizrl_agg1d_out",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute frequency 1440",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute path /data/BR_OUT/BizRulesAgg_1d/%Y/%M/%D/",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset bizrl_agg1d_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topAs_agg1d_out",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute startOffset 1",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute frequency 1440",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute endOffset 1",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute path /data/BR_OUT/TopAsAgg_1d/%Y/%M/%D/",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset topAs_agg1d_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topInt_agg1d_out",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute startOffset 1",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute frequency 1440",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute endOffset 1",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute path /data/BR_OUT/TopIntAgg_1d/%Y/%M/%D/",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset topInt_agg1d_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_bizagg_1d",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute startOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute frequency 1440",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute endOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute path /data/BR_OUT/BizRulesAgg_1d/%Y/%M/%D/X.MAPREDUCE.0.0",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_bizagg_1d attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topAsAgg_1d",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute frequency 1440",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute path /data/BR_OUT/TopAsAgg_1d/%Y/%M/%D/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_topAsAgg_1d attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topIntAgg_1d",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute frequency 1440",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute path /data/BR_OUT/TopIntAgg_1d/%Y/%M/%D/",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_topIntAgg_1d attribute startTime $Dset",
			"pmx subshell oozie add dataset bizrl_agg1w_in",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute startOffset 7",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute frequency 1",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute path /data/BR_OUT/BizRulesAgg_1d/%Y/%M/%D/",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute startTime $Dset",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1w_in attribute frequencyUnit day",
			"pmx subshell oozie add dataset bizrl_agg1w_out",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute frequency 7",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute path /data/BR_OUT/BizRulesAgg_1w/%Y/%M/%D/",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset bizrl_agg1w_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topAs_agg1w_out",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute startOffset 1",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute frequency 7",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute endOffset 1",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute path /data/BR_OUT/TopAsAgg_1w/%Y/%M/%D/",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset topAs_agg1w_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topInt_agg1w_out",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute startOffset 1",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute frequency 7",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute endOffset 1",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute path /data/BR_OUT/TopIntAgg_1w/%Y/%M/%D/",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset topInt_agg1w_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_bizagg_1w",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute startOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute frequency 7",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute endOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute path /data/BR_OUT/BizRulesAgg_1w/%Y/%M/%D/X.MAPREDUCE.0.0",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute frequencyUnit day",
			"pmx subshell oozie set dataset exp_bizagg_1w attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topAsAgg_1w",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute frequency 7",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute path /data/BR_OUT/TopAsAgg_1w/%Y/%M/%D/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute frequencyUnit day",
			"pmx subshell oozie set dataset exp_topAsAgg_1w attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topIntAgg_1w",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute frequency 7",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute path /data/BR_OUT/TopIntAgg_1w/%Y/%M/%D/",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute frequencyUnit day",
			"pmx subshell oozie set dataset exp_topIntAgg_1w attribute startTime $Dset",
			"pmx subshell oozie add dataset bizrl_agg1m_in",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute frequency 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute path /data/BR_OUT/BizRulesAgg_1d/%Y/%M/%D/",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute startTime $Dset",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1m_in attribute frequencyUnit day",
			"pmx subshell oozie add dataset bizrl_agg1m_out",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute frequency 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute path /data/BR_OUT/BizRulesAgg_Month/%Y/%M/",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute frequencyUnit month",
			"pmx subshell oozie set dataset bizrl_agg1m_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topAs_agg1m_out",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute startOffset 1",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute frequency 1",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute endOffset 1",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute path /data/BR_OUT/TopAsAgg_Month/%Y/%M/",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute frequencyUnit month",
			"pmx subshell oozie set dataset topAs_agg1m_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topInt_agg1m_out",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute startOffset 1",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute frequency 1",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute endOffset 1",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute path /data/BR_OUT/TopIntAgg_Month/%Y/%M/",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute frequencyUnit month",
			"pmx subshell oozie set dataset topInt_agg1m_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_bizrl_agg1m",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute startOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute frequency 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute endOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute path /data/BR_OUT/BizRulesAgg_Month/%Y/%M/X.MAPREDUCE.0.0",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute frequencyUnit month",
			"pmx subshell oozie set dataset exp_bizrl_agg1m attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topAs_agg1m",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute frequency 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute path /data/BR_OUT/TopAsAgg_Month/%Y/%M/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute frequencyUnit month",
			"pmx subshell oozie set dataset exp_topAs_agg1m attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topInt_agg1m",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute frequency 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute path /data/BR_OUT/TopIntAgg_Month/%Y/%M/",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute frequencyUnit month",
			"pmx subshell oozie set dataset exp_topInt_agg1m attribute startTime $Dset",
			"pmx subshell oozie add dataset bizrl_agg1d_est_in",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute startOffset 24",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute frequency 60",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute path /data/BR_OUT/BizRulesJob/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute startTime $Dset",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1d_est_in attribute frequencyUnit minute",
			"pmx subshell oozie add dataset bizrl_agg1d_est_out",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute frequency 1440",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute path /data/BR_OUT/BizRulesAgg_1d_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset bizrl_agg1d_est_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topAs_agg1d_est_out",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute startOffset 1",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute frequency 1440",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute endOffset 1",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute path /data/BR_OUT/TopAsAgg_1d_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset topAs_agg1d_est_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topInt_agg1d_est_out",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute startOffset 1",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute frequency 1440",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute endOffset 1",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute path /data/BR_OUT/TopIntAgg_1d_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset topInt_agg1d_est_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_bizrl_agg1d_est",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute frequency 1440",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute path /data/BR_OUT/BizRulesAgg_1d_EST/%Y/%M/%D/%H/X.MAPREDUCE.0.0",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_bizrl_agg1d_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topAs_agg1d_est",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute frequency 1440",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute path /data/BR_OUT/Sprint/TopAsAgg_1d_EST/%Y/%M/%D/%H/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_topAs_agg1d_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topInt_agg1d_est",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute frequency 1440",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute path /data/BR_OUT/Sprint/TopIntAgg_1d_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute frequencyUnit minute",
			"pmx subshell oozie set dataset exp_topInt_agg1d_est attribute startTime $Dset",
			"pmx subshell oozie add dataset bizrl_agg1w_est_in",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute startOffset 7",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute frequency 1",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute path /data/BR_OUT/BizRulesAgg_1d_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute startTime $Dset",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1w_est_in attribute frequencyUnit day",
			"pmx subshell oozie add dataset bizrl_agg1w_est_out",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute frequency 7",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute path /data/BR_OUT/BizRulesAgg_1w_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset bizrl_agg1w_est_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topas_agg1w_est_out",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute startOffset 1",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute frequency 7",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute endOffset 1",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute path /data/BR_OUT/TopAsAgg_1w_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset topas_agg1w_est_out attribute startTime $Dset",
			"pmx subshell oozie add dataset topInt_agg1w_est_out",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute startOffset 1",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute frequency 7",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute endOffset 1",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute outputOffset 1",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute doneFile _DONE",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute path /data/BR_OUT/TopIntAgg_1w_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute pathType hdfs",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset topInt_agg1w_est_out attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_bizagg_1w_est",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute frequency 7",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute path /data/BR_OUT/BizRulesAgg_1w_EST/%Y/%M/%D/%H/X.MAPREDUCE.0.0",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute frequencyUnit day",
			"pmx subshell oozie set dataset exp_bizagg_1w_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topAsAgg_1w_est",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute frequency 7",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute path /data/BR_OUT/TopAsAgg_1w_EST/%Y/%M/%D/%H/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute frequencyUnit day",
			"pmx subshell oozie set dataset exp_topAsAgg_1w_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topIntAgg_1w_est",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute frequency 7",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute path /data/BR_OUT/TopIntAgg_1w_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute frequencyUnit day",
			"pmx subshell oozie set dataset exp_topIntAgg_1w_est attribute startTime $Dset",
			"pmx subshell oozie add dataset bizrl_agg1m_in_est",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute frequency 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute path /data/BR_OUT/BizRulesAgg_1d_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute startTime $Dset",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1m_in_est attribute frequencyUnit day",
			"pmx subshell oozie add dataset bizrl_agg1m_out_est",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute startOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute frequency 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute endOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute outputOffset 1",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute path /data/BR_OUT/BizRulesAgg_Month_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute pathType hdfs",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute frequencyUnit month",
			"pmx subshell oozie set dataset bizrl_agg1m_out_est attribute startTime $Dset",
			"pmx subshell oozie add dataset topAs_agg1m_out_est",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute startOffset 1",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute frequency 1",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute endOffset 1",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute outputOffset 1",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute path /data/BR_OUT/TopAsAgg_Month_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute pathType hdfs",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute frequencyUnit month",
			"pmx subshell oozie set dataset topAs_agg1m_out_est attribute startTime $Dset",
			"pmx subshell oozie add dataset topInt_agg1m_out_est",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute startOffset 1",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute frequency 1",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute endOffset 1",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute outputOffset 1",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute path /data/BR_OUT/TopIntAgg_Month_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute pathType hdfs",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute frequencyUnit month",
			"pmx subshell oozie set dataset topInt_agg1m_out_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_bizrl_agg1m_est",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute frequency 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute path /data/BR_OUT/BizRulesAgg_Month_EST/%Y/%M/%D/%H/X.MAPREDUCE.0.0",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute frequencyUnit month",
			"pmx subshell oozie set dataset exp_bizrl_agg1m_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topAs_agg1m_est",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute frequency 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute path /data/BR_OUT/TopAsAgg_Month_EST/%Y/%M/%D/%H/X.MAPREDUCE.0.[0-1]",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute frequencyUnit month",
			"pmx subshell oozie set dataset exp_topAs_agg1m_est attribute startTime $Dset",
			"pmx subshell oozie add dataset exp_topInt_agg1m_est",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute startOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute frequency 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute endOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute outputOffset 1",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute doneFile _DONE",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute path /data/BR_OUT/TopIntAgg_Month_EST/%Y/%M/%D/%H/",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute pathType hdfs",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute frequencyUnit month",
			"pmx subshell oozie set dataset exp_topInt_agg1m_est attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_unrolled_in",
			"pmx subshell oozie set dataset ds_unrolled_in attribute startOffset 24",
			"pmx subshell oozie set dataset ds_unrolled_in attribute frequency 60",
			"pmx subshell oozie set dataset ds_unrolled_in attribute endOffset 1",
			"pmx subshell oozie set dataset ds_unrolled_in attribute outputOffset 0",
			"pmx subshell oozie set dataset ds_unrolled_in attribute path /data/BR_OUT/MasterJob/%Y/%M/%D/%H/X.MAPREDUCE.0.1",
			"pmx subshell oozie set dataset ds_unrolled_in attribute startTime $Dset",
			"pmx subshell oozie set dataset ds_unrolled_in attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_unrolled_in attribute frequencyUnit minute",
			"pmx subshell oozie add dataset ds_unrolled_out",
			"pmx subshell oozie set dataset ds_unrolled_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_unrolled_out attribute frequency 1440",
			"pmx subshell oozie set dataset ds_unrolled_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_unrolled_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_unrolled_out attribute path /data/BR_OUT/UnRolledAggJob/%Y/%M/%D/",
			"pmx subshell oozie set dataset ds_unrolled_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_unrolled_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset ds_unrolled_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_potAs_in",
			"pmx subshell oozie set dataset ds_potAs_in attribute startOffset 1",
			"pmx subshell oozie set dataset ds_potAs_in attribute frequency 1",
			"pmx subshell oozie set dataset ds_potAs_in attribute endOffset 1",
			"pmx subshell oozie set dataset ds_potAs_in attribute outputOffset 0",
			"pmx subshell oozie set dataset ds_potAs_in attribute path /data/BR_OUT/UnRolledAggJob/%Y/%M/%D/",
			"pmx subshell oozie set dataset ds_potAs_in attribute startTime $Dset",
			"pmx subshell oozie set dataset ds_potAs_in attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_potAs_in attribute frequencyUnit day",
			"pmx subshell oozie add dataset ds_potAs_out",
			"pmx subshell oozie set dataset ds_potAs_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_potAs_out attribute frequency 1",
			"pmx subshell oozie set dataset ds_potAs_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_potAs_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_potAs_out attribute path /data/BR_OUT/PotentialAsJob/%Y/%M/%D/",
			"pmx subshell oozie set dataset ds_potAs_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_potAs_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset ds_potAs_out attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_whiteAs_in",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute startOffset 7",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute frequency 1",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute endOffset 1",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute outputOffset 0",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute path /data/BR_OUT/PotentialAsJob/%Y/%M/%D/",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute frequencyUnit day",
			"pmx subshell oozie set dataset ds_whiteAs_in attribute startTime $Dset",
			"pmx subshell oozie add dataset ds_whiteAs_out",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute startOffset 1",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute frequency 7",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute endOffset 1",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute outputOffset 1",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute path /data/BR_OUT/WhiteAsList/%Y/%M/%D/",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute pathType hdfs",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute frequencyUnit day",
			"pmx subshell oozie set dataset ds_whiteAs_out attribute startTime $Dset",
			"pmx subshell oozie add dataset sla_ds_in",
			"pmx subshell oozie set dataset sla_ds_in attribute startOffset 1",
			"pmx subshell oozie set dataset sla_ds_in attribute endOffset 1",
			"pmx subshell oozie set dataset sla_ds_in attribute outputOffset 0",
			"pmx subshell oozie set dataset sla_ds_in attribute path /data/sla_logs/downloaded_log/%Y/%M/%D/%H/%mi/sla/ ",
			"pmx subshell oozie set dataset sla_ds_in attribute pathType hdfs                      ",
			"pmx subshell oozie set dataset sla_ds_in attribute startTime $Dset",
			"pmx subshell oozie set dataset sla_ds_in attribute doneFile _DONE",
			"pmx subshell oozie set dataset sla_ds_in attribute frequency 5",
			"pmx subshell oozie set dataset sla_ds_in attribute frequencyUnit minute",
			"pmx subshell oozie add dataset sla_ds_out",
			"pmx subshell oozie set dataset sla_ds_out attribute frequency 5",
			"pmx subshell oozie set dataset sla_ds_out attribute frequencyUnit minute",
			"pmx subshell oozie set dataset sla_ds_out attribute startOffset 1",
			"pmx subshell oozie set dataset sla_ds_out attribute endOffset 1",
			"pmx subshell oozie set dataset sla_ds_out attribute outputOffset 1",
			"pmx subshell oozie set dataset sla_ds_out attribute path /data/BR_OUT/SessionLogs/%Y/%M/%D/%H/%mi/",
			"pmx subshell oozie set dataset sla_ds_out attribute pathType hdfs                   ",
			"pmx subshell oozie set dataset sla_ds_out attribute startTime $Dset",
			"pmx subshell oozie add dataset eib",
			"pmx subshell oozie set dataset eib attribute frequency 3",
			"pmx subshell oozie set dataset eib attribute frequencyUnit hour",
			"pmx subshell oozie set dataset eib attribute path /data/routing/IBS/EIB/eib",
			"pmx subshell oozie set dataset eib attribute pathType hdfs",
			"pmx subshell oozie set dataset eib attribute startTime $Dset",
			"pmx subshell oozie add dataset asib",
			"pmx subshell oozie set dataset asib attribute frequency 3",
			"pmx subshell oozie set dataset asib attribute frequencyUnit hour",
			"pmx subshell oozie set dataset asib attribute path /data/routing/IBS/ASIB/asib",
			"pmx subshell oozie set dataset asib attribute pathType hdfs",
			"pmx subshell oozie set dataset asib attribute startTime $Dset",
			"pmx subshell oozie add dataset merged_ib_binary",
			"pmx subshell oozie set dataset merged_ib_binary attribute frequency 3",
			"pmx subshell oozie set dataset merged_ib_binary attribute frequencyUnit hour",
			"pmx subshell oozie set dataset merged_ib_binary attribute path /data/routing/IBS/mergedEibAsib/mergedEibAsib",
			"pmx subshell oozie set dataset merged_ib_binary attribute pathType hdfs",
			"pmx subshell oozie set dataset merged_ib_binary attribute startTime $Dset",
			"pmx subshell oozie add dataset pop",
			"pmx subshell oozie set dataset pop attribute frequency 3",
			"pmx subshell oozie set dataset pop attribute frequencyUnit hour",
			"pmx subshell oozie set dataset pop attribute path /data/routing/IBS/POP/pop",
			"pmx subshell oozie set dataset pop attribute pathType hdfs",
			"pmx subshell oozie set dataset pop attribute startTime $Dset",
			"pmx subshell oozie add dataset bgpdumps",
			"pmx subshell oozie set dataset bgpdumps attribute frequency 3",
			"pmx subshell oozie set dataset bgpdumps attribute frequencyUnit hour",
			"pmx subshell oozie set dataset bgpdumps attribute path /data/routing/Bgpdumps/bview",
			"pmx subshell oozie set dataset bgpdumps attribute pathType local",
			"pmx subshell oozie set dataset bgpdumps attribute startTime $Dset",
			"pmx subshell oozie add dataset gleaning",
			"pmx subshell oozie set dataset gleaning attribute frequency 1",
			"pmx subshell oozie set dataset gleaning attribute frequencyUnit hour",
			"pmx subshell oozie set dataset gleaning attribute path /data/_BizreflexCubes/Gleaning/gleaning",
			"pmx subshell oozie set dataset gleaning attribute pathType hdfs",
			"pmx subshell oozie set dataset gleaning attribute startTime $Dset",
			"pmx subshell oozie add dataset netflow",
			"pmx subshell oozie set dataset netflow attribute frequency 1",
			"pmx subshell oozie set dataset netflow attribute frequencyUnit day",
			"pmx subshell oozie set dataset netflow attribute pathType hdfs",
			"pmx subshell oozie set dataset netflow attribute startTime $Dset",
			"pmx subshell oozie set dataset netflow attribute path /data/collector/%Y/%M/%D/",
			"pmx subshell oozie set dataset netflow attribute startOffset 0",
			"pmx subshell oozie set dataset netflow attribute endOffset 1",
			"pmx subshell oozie add dataset map_reduce",
			"pmx subshell oozie set dataset map_reduce attribute frequency 1",
			"pmx subshell oozie set dataset map_reduce attribute frequencyUnit day",
			"pmx subshell oozie set dataset map_reduce attribute pathType hdfs",
			"pmx subshell oozie set dataset map_reduce attribute startTime $Dset",
			"pmx subshell oozie set dataset map_reduce attribute path /data/OozieOut/BaseJob/%Y/%M/%D/   ",
			"pmx subshell oozie set dataset map_reduce attribute startOffset 0",
			"pmx subshell oozie set dataset map_reduce attribute endOffset 1"

		);

	push (  @cmds,

			"pmx subshell oozie add job TempPotAsJob PotentialAsJob /opt/etc/oozie/PotentialAsCubes",
			"pmx subshell oozie set job TempPotAsJob attribute jobFrequency 1440",
			"pmx subshell oozie set job TempPotAsJob attribute jobStart $Dset",
			"pmx subshell oozie set job TempPotAsJob attribute jobEnd 2055-09-27T00:00Z",
			"pmx subshell oozie set job TempPotAsJob attribute frequencyUnit minute",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute inputDatasets ds_rollup_in",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute mainClass com.guavus.mapred.reflex.bizreflex.job.UnRolledUpJob.UnRolledUpCubes",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute configFile /data/configs/jobs/config_aslist.xml",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute outputDataset ds_rollup_out",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute instaPort 11111",
			"pmx subshell oozie set job TempPotAsJob action ExecuteRollUpJob attribute instaHost 192.168.151.241",
			"pmx subshell oozie set job TempPotAsJob action ExecutePotentialAsJob attribute inputDatasets ds_rollup_out",
			"pmx subshell oozie set job TempPotAsJob action ExecutePotentialAsJob attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job TempPotAsJob action ExecutePotentialAsJob attribute mainClass com.guavus.mapred.reflex.bizreflex.job.PotentialAsJob.PotentialAs",
			"pmx subshell oozie set job TempPotAsJob action ExecutePotentialAsJob attribute configFile /data/configs/jobs/config_aslist.xml",
			"pmx subshell oozie set job TempPotAsJob action ExecutePotentialAsJob attribute outputDataset temp_potAs_out",
			"pmx subshell oozie add job master_job BizreflexMasterJob /opt/etc/oozie/BizreflexMasterCubes",
			"pmx subshell oozie set job master_job attribute jobStart $Dset",
			"pmx subshell oozie set job master_job attribute jobFrequency 60      ",
			"pmx subshell oozie set job master_job attribute jobEnd 2055-08-29T11:00Z",
			"pmx subshell oozie set job master_job attribute frequencyUnit minute",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.MasterJob.MasterCubes",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute configFile /data/configs/jobs/config_masterjob.xml",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute inputDatasets ds_base_in          ",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute outputDataset ds_base_out          ",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute instaHost 192.168.112.136",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute instaPort 11112",
			"pmx subshell oozie set job master_job action ExecuteBaseJob  attribute snapshotDatasets ds_base_out",
			"pmx subshell oozie set job master_job action ExecutePrefixJob attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job master_job action ExecutePrefixJob attribute mainClass com.guavus.mapred.reflex.bizreflex.job.PrefixAsJob.PrefixAsCubes",
			"pmx subshell oozie set job master_job action ExecutePrefixJob attribute configFile /data/configs/jobs/config_masterjob.xml",
			"pmx subshell oozie set job master_job action ExecutePrefixJob attribute outputDataset ds_prefix_out",
			"pmx subshell oozie set job master_job action ExecutePrefixJob attribute snapshotDatasets ds_prefix_out",
			"pmx subshell oozie add job bizrules_job BizRulesJob /opt/etc/oozie/Reflex/BizRulesCubes",
			"pmx subshell oozie set job bizrules_job attribute jobStart $Dset",
			"pmx subshell oozie set job bizrules_job attribute jobFrequency 60",
			"pmx subshell oozie set job bizrules_job attribute jobEnd 2055-08-29T11:00Z",
			"pmx subshell oozie set job bizrules_job attribute frequencyUnit minute",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.BizRulesJob.BizRulesJobCubes",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute configFile /data/configs/jobs/config_bizrules.xml",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute inputDatasets ds_bizrl_ds_in",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute outputDataset ds_bizrl_ds_out",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute instaHost 192.168.112.136",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute instaPort 11112",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute postgresSqlHost 192.168.112.136",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute postgresSqlPort 5432",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute postgresSql_DBname commondb_sprint",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute postgresSql_tableSuffix $prop->{suffix_name}",
			"pmx subshell oozie set job bizrules_job action BizRulesAction  attribute snapshotDatasets ds_bizrl_ds_out",
			"pmx subshell oozie set job bizrules_job action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job bizrules_job action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job bizrules_job action TopASPathAction attribute configFile /data/configs/jobs/config_bizrules.xml",
			"pmx subshell oozie set job bizrules_job action TopASPathAction attribute inputDatasets ds_bizrl_ds_out",
			"pmx subshell oozie set job bizrules_job action TopASPathAction attribute outputDataset ds_topAs_ds_out",
			"pmx subshell oozie set job bizrules_job action TopASPathAction attribute snapshotDatasets ds_topAs_ds_out",
			"pmx subshell oozie set job bizrules_job action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job bizrules_job action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job bizrules_job action TopInteractionAction attribute inputDatasets ds_bizrl_ds_out",
			"pmx subshell oozie set job bizrules_job action TopInteractionAction attribute configFile /data/configs/jobs/config_bizrules.xml",
			"pmx subshell oozie set job bizrules_job action TopInteractionAction attribute outputDataset ds_topInt_ds_out",
			"pmx subshell oozie set job bizrules_job action TopInteractionAction attribute snapshotDatasets ds_topInt_ds_out",
			"pmx subshell oozie add job export_job ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_job attribute jobStart $Dset",
			"pmx subshell oozie set job export_job attribute jobEnd 2055-04-01T00:00Z",
			"pmx subshell oozie set job export_job attribute jobFrequency 60",
			"pmx subshell oozie set job export_job attribute frequencyUnit minute",
			"pmx subshell oozie set job export_job action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_job action ExporterAction attribute instaPort 11112",
			"pmx subshell oozie set job export_job action ExporterAction attribute instaHost 192.168.112.136",
			"pmx subshell oozie set job export_job action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_job action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_job action ExporterAction attribute binClasses NPENTITY_60min",
			"pmx subshell oozie set job export_job action ExporterAction attribute binClasses NPENTITY_5min",
			"pmx subshell oozie set job export_job action ExporterAction attribute binClasses 1hAggr",
			"pmx subshell oozie set job export_job action ExporterAction attribute binClasses INSTATIME_60min",
			"pmx subshell oozie set job export_job action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_job action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_job action ExporterAction attribute maxTimeout 600",
			"pmx subshell oozie set job export_job action ExporterAction attribute minTimeout 300",
			"pmx subshell oozie set job export_job action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_job action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_job action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_job action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_job action ExporterAction attribute useNoreserveInstaAPI true",
			"pmx subshell oozie set job export_job action ExporterAction attribute srcDatasets exp_ds_base_out",
			"pmx subshell oozie set job export_job action ExporterAction attribute srcDatasets exp_ds_prefix_out",
			"pmx subshell oozie set job export_job action ExporterAction attribute srcDatasets exp_ds_bizr_out",
			"pmx subshell oozie set job export_job action ExporterAction attribute srcDatasets exp_ds_topAs_out",
			"pmx subshell oozie set job export_job action ExporterAction attribute srcDatasets exp_ds_topInt_out",
			"pmx subshell oozie add job aggregate_1d BizAggregatedJob /opt/etc/oozie/Reflex/BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1d attribute jobStart $Dset",
			"pmx subshell oozie set job aggregate_1d attribute jobFrequency 1",
			"pmx subshell oozie set job aggregate_1d attribute jobEnd 2055-04-23T00:00Z",
			"pmx subshell oozie set job aggregate_1d attribute frequencyUnit day",
			"pmx subshell oozie set job aggregate_1d action ExecuteAggregatedBizJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1d action ExecuteAggregatedBizJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregatedBizJob.BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1d action ExecuteAggregatedBizJob  attribute configFile /data/configs/jobs/config_agg_1d.xml",
			"pmx subshell oozie set job aggregate_1d action ExecuteAggregatedBizJob  attribute inputDatasets bizrl_agg1d_in",
			"pmx subshell oozie set job aggregate_1d action ExecuteAggregatedBizJob  attribute outputDataset bizrl_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action ExecuteAggregatedBizJob  attribute snapshotDatasets bizrl_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1d action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job aggregate_1d action TopASPathAction attribute configFile /data/configs/jobs/config_agg_1d.xml",
			"pmx subshell oozie set job aggregate_1d action TopASPathAction attribute inputDatasets bizrl_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action TopASPathAction attribute outputDataset topAs_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action TopASPathAction attribute snapshotDatasets topAs_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1d action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job aggregate_1d action TopInteractionAction attribute inputDatasets bizrl_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action TopInteractionAction attribute configFile /data/configs/jobs/config_agg_1d.xml",
			"pmx subshell oozie set job aggregate_1d action TopInteractionAction attribute outputDataset topInt_agg1d_out",
			"pmx subshell oozie set job aggregate_1d action TopInteractionAction attribute snapshotDatasets topInt_agg1d_out",
			"pmx subshell oozie add job export_agg_1d ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_agg_1d attribute jobStart $Dset",
			"pmx subshell oozie set job export_agg_1d attribute jobEnd 2055-04-23T00:00Z",
			"pmx subshell oozie set job export_agg_1d attribute jobFrequency 1",
			"pmx subshell oozie set job export_agg_1d attribute frequencyUnit day",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute instaPort 11111",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute instaHost 192.168.112.130",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute binClasses 1dAggr",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute binClassGranSuffix Day",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute maxTimeout 600",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute minTimeout 300",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute srcDatasets exp_bizagg_1d",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute srcDatasets exp_topAsAgg_1d",
			"pmx subshell oozie set job export_agg_1d action ExporterAction attribute srcDatasets exp_topIntAgg_1d",
			"pmx subshell oozie add job aggregate_1w BizAggregatedJob /opt/etc/oozie/Reflex/BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1w attribute jobStart $Dset",
			"pmx subshell oozie set job aggregate_1w attribute jobFrequency 7",
			"pmx subshell oozie set job aggregate_1w attribute jobEnd 2055-04-23T00:00Z",
			"pmx subshell oozie set job aggregate_1w attribute frequencyUnit day",
			"pmx subshell oozie set job aggregate_1w action ExecuteAggregatedBizJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1w action ExecuteAggregatedBizJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregatedBizJob.BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1w action ExecuteAggregatedBizJob  attribute configFile /data/configs/jobs/config_agg_1w.xml",
			"pmx subshell oozie set job aggregate_1w action ExecuteAggregatedBizJob  attribute inputDatasets bizrl_agg1w_in",
			"pmx subshell oozie set job aggregate_1w action ExecuteAggregatedBizJob  attribute outputDataset bizrl_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action ExecuteAggregatedBizJob  attribute snapshotDatasets bizrl_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1w action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job aggregate_1w action TopASPathAction attribute configFile /data/configs/jobs/config_agg_1w.xml",
			"pmx subshell oozie set job aggregate_1w action TopASPathAction attribute inputDatasets bizrl_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action TopASPathAction attribute outputDataset topAs_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action TopASPathAction attribute snapshotDatasets topAs_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1w action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job aggregate_1w action TopInteractionAction attribute inputDatasets bizrl_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action TopInteractionAction attribute configFile /data/configs/jobs/config_agg_1w.xml",
			"pmx subshell oozie set job aggregate_1w action TopInteractionAction attribute outputDataset topInt_agg1w_out",
			"pmx subshell oozie set job aggregate_1w action TopInteractionAction attribute snapshotDatasets topInt_agg1w_out",
			"pmx subshell oozie add job export_agg_1w ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_agg_1w attribute jobStart $Dset",
			"pmx subshell oozie set job export_agg_1w attribute jobEnd 2055-04-23T00:00Z",
			"pmx subshell oozie set job export_agg_1w attribute jobFrequency 7",
			"pmx subshell oozie set job export_agg_1w attribute frequencyUnit day",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute instaPort 11111",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute instaHost 192.168.112.130",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute binClasses 1wAggr",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute binClassGranSuffix Week",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute maxTimeout 6000",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute minTimeout 3000",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute srcDatasets exp_bizagg_1w",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute srcDatasets exp_topAsAgg_1w",
			"pmx subshell oozie set job export_agg_1w action ExporterAction attribute srcDatasets exp_topIntAgg_1w",
			"pmx subshell oozie add job aggregate_1m BizAggregatedJob /opt/etc/oozie/Reflex/BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1m attribute jobStart $Dset",
			"pmx subshell oozie set job aggregate_1m attribute jobFrequency 1",
			"pmx subshell oozie set job aggregate_1m attribute jobEnd 2055-09-01T00:00Z",
			"pmx subshell oozie set job aggregate_1m attribute frequencyUnit month",
			"pmx subshell oozie set job aggregate_1m action ExecuteAggregatedBizJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1m action ExecuteAggregatedBizJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregatedBizJob.BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1m action ExecuteAggregatedBizJob  attribute configFile /data/configs/jobs/config_agg_1m.xml",
			"pmx subshell oozie set job aggregate_1m action ExecuteAggregatedBizJob  attribute inputDatasets bizrl_agg1m_in",
			"pmx subshell oozie set job aggregate_1m action ExecuteAggregatedBizJob  attribute outputDataset bizrl_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action ExecuteAggregatedBizJob  attribute snapshotDatasets bizrl_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1m action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job aggregate_1m action TopASPathAction attribute configFile /data/configs/jobs/config_agg_1m.xml",
			"pmx subshell oozie set job aggregate_1m action TopASPathAction attribute inputDatasets bizrl_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action TopASPathAction attribute outputDataset topAs_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action TopASPathAction attribute snapshotDatasets topAs_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1m action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job aggregate_1m action TopInteractionAction attribute inputDatasets bizrl_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action TopInteractionAction attribute configFile /data/configs/jobs/config_agg_1m.xml",
			"pmx subshell oozie set job aggregate_1m action TopInteractionAction attribute outputDataset topInt_agg1m_out",
			"pmx subshell oozie set job aggregate_1m action TopInteractionAction attribute snapshotDatasets topInt_agg1m_out",
			"pmx subshell oozie add job export_agg_1m ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_agg_1m attribute jobStart $Dset",
			"pmx subshell oozie set job export_agg_1m attribute jobEnd 2055-09-01T00:00Z",
			"pmx subshell oozie set job export_agg_1m attribute jobFrequency 1",
			"pmx subshell oozie set job export_agg_1m attribute frequencyUnit month",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute instaPort 11114",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute instaHost 192.168.112.136",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute binClasses 1mAggr",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute binClassGranSuffix Month",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute maxTimeout 9000",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute minTimeout 6000",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute srcDatasets exp_bizrl_agg1m",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute srcDatasets exp_topAs_agg1m",
			"pmx subshell oozie set job export_agg_1m action ExporterAction attribute srcDatasets exp_topInt_agg1m",
			"pmx subshell oozie add job aggregate_1d_est BizAggregatedJob /opt/etc/oozie/Reflex/BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1d_est attribute jobStart $Dset",
			"pmx subshell oozie set job aggregate_1d_est attribute jobFrequency 1",
			"pmx subshell oozie set job aggregate_1d_est attribute jobEnd 2055-04-23T05:00Z",
			"pmx subshell oozie set job aggregate_1d_est attribute frequencyUnit day",
			"pmx subshell oozie set job aggregate_1d_est action ExecuteAggregatedBizJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1d_est action ExecuteAggregatedBizJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregatedBizJob.BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1d_est action ExecuteAggregatedBizJob  attribute configFile /data/configs/jobs/config_agg_1d_est.xml",
			"pmx subshell oozie set job aggregate_1d_est action ExecuteAggregatedBizJob  attribute inputDatasets bizrl_agg1d_est_in",
			"pmx subshell oozie set job aggregate_1d_est action ExecuteAggregatedBizJob  attribute outputDataset bizrl_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action ExecuteAggregatedBizJob  attribute snapshotDatasets bizrl_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1d_est action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job aggregate_1d_est action TopASPathAction attribute configFile /data/configs/jobs/config_agg_1d_est.xml",
			"pmx subshell oozie set job aggregate_1d_est action TopASPathAction attribute inputDatasets bizrl_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action TopASPathAction attribute outputDataset topAs_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action TopASPathAction attribute snapshotDatasets topAs_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1d_est action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job aggregate_1d_est action TopInteractionAction attribute inputDatasets bizrl_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action TopInteractionAction attribute configFile /data/configs/jobs/config_agg_1d_est.xml",
			"pmx subshell oozie set job aggregate_1d_est action TopInteractionAction attribute outputDataset topInt_agg1d_est_out",
			"pmx subshell oozie set job aggregate_1d_est action TopInteractionAction attribute snapshotDatasets topInt_agg1d_est_out",
			"pmx subshell oozie add job export_agg_1d_est ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_agg_1d_est attribute jobStart $Dset",
			"pmx subshell oozie set job export_agg_1d_est attribute jobEnd 2055-06-03T05:00Z",
			"pmx subshell oozie set job export_agg_1d_est attribute jobFrequency 1",
			"pmx subshell oozie set job export_agg_1d_est attribute frequencyUnit day",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute instaPort 22222",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute instaHost 192.168.112.136",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute binClasses 1dAggr",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute binClassGranSuffix Day",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute maxTimeout 600",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute minTimeout 300",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute srcDatasets exp_bizrl_agg1d_est",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute srcDatasets exp_topAs_agg1d_est",
			"pmx subshell oozie set job export_agg_1d_est action ExporterAction attribute srcDatasets exp_topInt_agg1d_est",
			"pmx subshell oozie add job aggregate_1w_est BizAggregatedJob /opt/etc/oozie/Reflex/BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1w_est attribute jobStart $Dset",
			"pmx subshell oozie set job aggregate_1w_est attribute jobFrequency 7",
			"pmx subshell oozie set job aggregate_1w_est attribute jobEnd 2055-04-23T05:00Z",
			"pmx subshell oozie set job aggregate_1w_est attribute frequencyUnit day",
			"pmx subshell oozie set job aggregate_1w_est action ExecuteAggregatedBizJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1w_est action ExecuteAggregatedBizJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregatedBizJob.BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1w_est action ExecuteAggregatedBizJob  attribute configFile /data/configs/jobs/config_agg_1w_est.xml",
			"pmx subshell oozie set job aggregate_1w_est action ExecuteAggregatedBizJob  attribute inputDatasets bizrl_agg1w_est_in",
			"pmx subshell oozie set job aggregate_1w_est action ExecuteAggregatedBizJob  attribute outputDataset bizrl_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action ExecuteAggregatedBizJob  attribute snapshotDatasets bizrl_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1w_est action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job aggregate_1w_est action TopASPathAction attribute configFile /data/configs/jobs/config_agg_1w_est.xml",
			"pmx subshell oozie set job aggregate_1w_est action TopASPathAction attribute inputDatasets bizrl_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action TopASPathAction attribute outputDataset topas_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action TopASPathAction attribute snapshotDatasets topas_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1w_est action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job aggregate_1w_est action TopInteractionAction attribute inputDatasets bizrl_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action TopInteractionAction attribute configFile /data/configs/jobs/config_agg_1w_est.xml",
			"pmx subshell oozie set job aggregate_1w_est action TopInteractionAction attribute outputDataset topInt_agg1w_est_out",
			"pmx subshell oozie set job aggregate_1w_est action TopInteractionAction attribute snapshotDatasets topInt_agg1w_est_out",
			"pmx subshell oozie add job export_agg_1w_est ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_agg_1w_est attribute jobStart $Dset",
			"pmx subshell oozie set job export_agg_1w_est attribute jobEnd 2055-04-23T05:00Z",
			"pmx subshell oozie set job export_agg_1w_est attribute jobFrequency 7",
			"pmx subshell oozie set job export_agg_1w_est attribute frequencyUnit day",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute instaPort 11111",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute instaHost 192.168.112.130",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute binClasses 1wAggr",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute binClassGranSuffix Week",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute maxTimeout 6000",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute minTimeout 3000",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute srcDatasets exp_bizagg_1w_est",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute srcDatasets exp_topAsAgg_1w_est",
			"pmx subshell oozie set job export_agg_1w_est action ExporterAction attribute srcDatasets exp_topIntAgg_1w_est",
			"pmx subshell oozie add job aggregate_1m_est BizAggregatedJob /opt/etc/oozie/Reflex/BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1m_est attribute jobStart $Dset",
			"pmx subshell oozie set job aggregate_1m_est attribute jobFrequency 1",
			"pmx subshell oozie set job aggregate_1m_est attribute jobEnd 2055-09-01T05:00Z",
			"pmx subshell oozie set job aggregate_1m_est attribute frequencyUnit month",
			"pmx subshell oozie set job aggregate_1m_est action ExecuteAggregatedBizJob  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1m_est action ExecuteAggregatedBizJob  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregatedBizJob.BizAggregatedJob",
			"pmx subshell oozie set job aggregate_1m_est action ExecuteAggregatedBizJob  attribute configFile /data/configs/jobs/config_agg_1m_est.xml",
			"pmx subshell oozie set job aggregate_1m_est action ExecuteAggregatedBizJob  attribute inputDatasets bizrl_agg1m_in_est",
			"pmx subshell oozie set job aggregate_1m_est action ExecuteAggregatedBizJob  attribute outputDataset bizrl_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action ExecuteAggregatedBizJob  attribute snapshotDatasets bizrl_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action TopASPathAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1m_est action TopASPathAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopASPath.TopASPath",
			"pmx subshell oozie set job aggregate_1m_est action TopASPathAction attribute configFile /data/configs/jobs/config_agg_1m_est.xml",
			"pmx subshell oozie set job aggregate_1m_est action TopASPathAction attribute inputDatasets bizrl_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action TopASPathAction attribute outputDataset topAs_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action TopASPathAction attribute snapshotDatasets topAs_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action TopInteractionAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job aggregate_1m_est action TopInteractionAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.TopInteractions.TopInteraction",
			"pmx subshell oozie set job aggregate_1m_est action TopInteractionAction attribute inputDatasets bizrl_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action TopInteractionAction attribute configFile /data/configs/jobs/config_agg_1m_est.xml",
			"pmx subshell oozie set job aggregate_1m_est action TopInteractionAction attribute outputDataset topInt_agg1m_out_est",
			"pmx subshell oozie set job aggregate_1m_est action TopInteractionAction attribute snapshotDatasets topInt_agg1m_out_est",
			"pmx subshell oozie add job export_agg_1m_est ExporterJob /opt/etc/oozie/CubeExporter",
			"pmx subshell oozie set job export_agg_1m_est attribute jobStart $Dset",
			"pmx subshell oozie set job export_agg_1m_est attribute jobEnd 2055-09-01T05:00Z",
			"pmx subshell oozie set job export_agg_1m_est attribute jobFrequency 1",
			"pmx subshell oozie set job export_agg_1m_est attribute frequencyUnit month",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute binInterval 3600",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute instaPort 11114",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute instaHost 192.168.112.136",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute aggregationInterval -1",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute binClasses 1mAggr",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute binClassGranSuffix Month",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute fileType Seq",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute maxTimeout 9000",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute minTimeout 6000",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute retrySleep 300",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute hadoopClientOption -Xmx20000M",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute solutionName reflex.bizreflex",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute binsToPersistOneTime 0",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute srcDatasets exp_bizrl_agg1m_est",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute srcDatasets exp_topAs_agg1m_est",
			"pmx subshell oozie set job export_agg_1m_est action ExporterAction attribute srcDatasets exp_topInt_agg1m_est",
			"pmx subshell oozie add job unrolledAsJob MapRedJob /opt/etc/oozie/MapRed",
			"pmx subshell oozie set job unrolledAsJob attribute jobStart $Dset",
			"pmx subshell oozie set job unrolledAsJob attribute jobFrequency 1440",
			"pmx subshell oozie set job unrolledAsJob attribute jobEnd 2055-08-29T00:30Z",
			"pmx subshell oozie set job unrolledAsJob attribute frequencyUnit minute",
			"pmx subshell oozie set job unrolledAsJob action MapRedAction  attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job unrolledAsJob action MapRedAction  attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AggregateJob.BizreflexAgg",
			"pmx subshell oozie set job unrolledAsJob action MapRedAction  attribute configFile /data/configs/jobs/config_aslist.xml",
			"pmx subshell oozie set job unrolledAsJob action MapRedAction  attribute inputDatasets ds_unrolled_in",
			"pmx subshell oozie set job unrolledAsJob action MapRedAction  attribute outputDataset ds_unrolled_out",
			"pmx subshell oozie set job unrolledAsJob action MapRedAction  attribute snapshotDatasets ds_unrolled_out",
			"pmx subshell oozie add job PotAsJob MapRedJob /opt/etc/oozie/MapRed",
			"pmx subshell oozie set job PotAsJob attribute jobFrequency 1",
			"pmx subshell oozie set job PotAsJob attribute jobStart $Dset",
			"pmx subshell oozie set job PotAsJob attribute jobEnd 2055-09-03T03:00Z",
			"pmx subshell oozie set job PotAsJob attribute frequencyUnit day",
			"pmx subshell oozie set job PotAsJob action MapRedAction attribute inputDatasets ds_potAs_in",
			"pmx subshell oozie set job PotAsJob action MapRedAction attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job PotAsJob action MapRedAction attribute mainClass com.guavus.mapred.reflex.bizreflex.job.PotentialAsJob.PotentialAs",
			"pmx subshell oozie set job PotAsJob action MapRedAction attribute configFile /data/configs/jobs/config_aslist.xml",
			"pmx subshell oozie set job PotAsJob action MapRedAction attribute outputDataset ds_potAs_out",
			"pmx subshell oozie set job PotAsJob action MapRedAction attribute snapshotDatasets ds_potAs_out",
			"pmx subshell oozie add job ExecWhiteListJob AsWhiteListJob /opt/etc/oozie/AsWhiteList",
			"pmx subshell oozie set job ExecWhiteListJob attribute jobFrequency 7",
			"pmx subshell oozie set job ExecWhiteListJob attribute jobStart $Dset",
			"pmx subshell oozie set job ExecWhiteListJob attribute jobEnd 2055-12-11T00:40Z",
			"pmx subshell oozie set job ExecWhiteListJob attribute frequencyUnit day",
			"pmx subshell oozie set job ExecWhiteListJob action ExecuteAsWhiteListJob attribute inputDatasets ds_whiteAs_in",
			"pmx subshell oozie set job ExecWhiteListJob action ExecuteAsWhiteListJob attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job ExecWhiteListJob action ExecuteAsWhiteListJob attribute mainClass com.guavus.mapred.reflex.bizreflex.job.AsWhiteListJob.AsWhiteList",
			"pmx subshell oozie set job ExecWhiteListJob action ExecuteAsWhiteListJob attribute configFile /data/configs/jobs/config_aslist.xml",
			"pmx subshell oozie set job ExecWhiteListJob action ExecuteAsWhiteListJob attribute outputDataset ds_whiteAs_out",
			"pmx subshell oozie add job sessionLogsJob UserSessionJob /opt/etc/oozie/UserSession",
			"pmx subshell oozie set job sessionLogsJob attribute jobStart $Dset",
			"pmx subshell oozie set job sessionLogsJob attribute jobEnd 2055-09-03T19:55Z",
			"pmx subshell oozie set job sessionLogsJob attribute jobFrequency 5",
			"pmx subshell oozie set job sessionLogsJob action ProcessLoginJob attribute configFile /data/configs/jobs/config_userSession.xml",
			"pmx subshell oozie set job sessionLogsJob action ProcessLoginJob attribute jarFile /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job sessionLogsJob action ProcessLoginJob attribute mainClass com.guavus.mapred.reflex.bizreflex.job.UserSessionJob.UserSession",
			"pmx subshell oozie set job sessionLogsJob action ProcessLoginJob attribute inputDatasets sla_ds_in",
			"pmx subshell oozie set job sessionLogsJob action ProcessLoginJob attribute outputDataset sla_ds_out",
			"pmx subshell oozie set job sessionLogsJob action ProcessLoginJob attribute timeout 30",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute aggregationInterval -1",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute binInterval 300",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute binClasses SLA_5min",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute className com.guavus.exporter.Exporter",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute fileType Seq                         ",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute instaHost 192.168.151.241",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute instaPort 11111",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute jarName /opt/tms/java/CubeCreator.jar",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute solutionName reflex.bizreflex                        ",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute srcDatasets  sla_ds_out",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute maxTimeout 70",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute minTimeout 30",
			"pmx subshell oozie set job sessionLogsJob action ExportData attribute retrySleep 300",
			"pmx subshell oozie add job sla1 SLA_CleanUpProcessedData /opt/etc/oozie/Reflex/SLA_CleanUpProcessedData",
			"pmx subshell oozie set job sla1 attribute jobStart  $Dset",
			"pmx subshell oozie set job sla1 attribute jobEnd 2020-04-15T01:55Z",
			"pmx subshell oozie set job sla1 attribute jobFrequency 15",
			"pmx subshell oozie set job sla1 attribute frequencyUnit day",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupOffset 12",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupDatasets eib",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupDatasets asib",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupDatasets merged_ib_binary",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupDatasets pop",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupDatasets gleaning",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute cleanupDatasets bgpdumps",
			"pmx subshell oozie set job sla1 action SLA_CleanUpProcessedDataAction attribute solutionName bizreflex",
			"pmx subshell oozie add job sla2 SLA_DataCleanUp /opt/etc/oozie/Reflex/SLA_DataCleanUp",
			"pmx subshell oozie set job sla2 attribute jobFrequency 15",
			"pmx subshell oozie set job sla2 attribute frequencyUnit day",
			"pmx subshell oozie set job sla2 attribute jobStart $Dset",
			"pmx subshell oozie set job sla2 attribute jobEnd 2020-04-15T02:00Z",
			"pmx subshell oozie set job sla2 action SLA_DataCleanUpAction attribute cleanupOffset 12",
			"pmx subshell oozie set job sla2 action SLA_DataCleanUpAction attribute cleanupDatasets netflow",
			"pmx subshell oozie set job sla2 action SLA_DataCleanUpAction attribute cleanupDatasets map_reduce"
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

