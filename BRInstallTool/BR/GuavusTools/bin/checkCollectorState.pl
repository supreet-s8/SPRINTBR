#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor;
my $cli='/opt/tms/bin/cli';
my $pmx='/opt/tps/bin/pmx.py';
my $cluster;
my $process;
my $expected_jobs={
'Atlas' => 1, 
'CleanupAtlas' => 1, 
'CleanupCollector' => 1, 
'CleanupLogs' => 1, 
'Distcp' => 1, 
'Ipfixcp1' => 1, 
'Ipfixcp2' => 1, 
'Ipfixcp3' => 1, 
'Ipfixcp4' => 1, 
'Ipfixcp5' => 1, 
'Ipfixcp6' => 1, 
'Radiuscp1' => 1, 
'Radiuscp2' => 1, 
'SubscriberIBcp' => 1, 
};
$|=1;

open (STDIN,"$cli -t 'en' 'show cluster local' |");
while (<>) {
  if ($_=~/Node Role: (\w+)$/) {
    $cluster->{'role'}=$1;
  } elsif ($_=~/Node address: (\d+.\d+.\d+.\d+),/) {
    $cluster->{'address'}=$1;
  } elsif ($_=~/Node State: (\w+)$/) {
    $cluster->{'state'}=$1;
  } elsif ($_=~/Hostname: (\S+)$/i) {
    $cluster->{'hostname'}=$1;
  }
}

open (STDIN,"$cli -t 'en' 'show pm process collector' |");
while (<>) {
  if ($_=~/Launchable:\s+(\w+)/) {
    $process->{'launchable'}=$1;
  } elsif ($_=~/Auto-launch:\s+(\w+)/) {
    $process->{'launch'}=$1;
  } elsif ($_=~/Auto-relaunch:\s+(\w+)/) {
    $process->{'relaunch'}=$1;
  } elsif ($_=~/Current status:\s+(\w+)/) {
    $process->{'status'}=$1;
  }
}
my @jobs = `$pmx "subshell oozie show coordinator RUNNING jobs" | grep -v "^-*\$" | grep -v App | cut -f 2 | sort `;
map { s/\n//g } @jobs;
my %hash = map { $_ => 1 } @jobs;
print "  =============================================================================\n";
print "   Cluster Status - \n";
print "   Current Node        : $cluster->{'hostname'} ($cluster->{'address'}) \n";
if ($cluster->{'state'}=~/online/i) { print color 'bold green'; } else { print color 'bold red'; }
print "   Current Role/Status : $cluster->{'role'} - $cluster->{'state'} \n";
print color 'reset';
print "  =============================================================================\n";
print "   Collector Process State - \n";
print "   Configuration:\t Launchable  : $process->{'launchable'}\n";
print "                 \t Auto Launch : $process->{'launch'}\n";
print "                 \t AutoRelaunch: $process->{'relaunch'}\n";
if ($process->{'status'}=~/running/i) { print color 'bold green'; } else { print color 'bold red'; }
print "   Status: $process->{'status'}\n";
print color 'reset';
print "  =============================================================================\n";
print "  Current Co-ordinator Jobs Running on this node - \n";
foreach my $job (sort keys %{$expected_jobs}) { 
  print "\t$job - ";
  if (exists $hash{$job}) { print color 'bold green'; print "OK\n"; print color 'reset'; } 
    else { print color 'bold red'; print "NOT FOUND\n"; print color 'reset'; } 
}
print "  =============================================================================\n";
