#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor;
# Receive data from ICNB interface. Update if otherwise
my $dev="icnb";


# --- Do not edit below ---
my $data;
my $DELAY=300;
my $ipfixcount=0;
my $pilotcount=0;
$|=1;
print "  =============================================================================\n";
print "Capturing records for 300 seconds....\n" ;
open (STDIN,"tethereal -i $dev -n -T text -a duration:$DELAY |");
while (<>) {
  if (/UDP Source port\:\s+\d+\s+Destination port\: 4000/i) {
    (/\d+\s+(\d+.\d+.\d+.\d+)\s\-\>/);
    $data->{$1}->{'4000'}++;$ipfixcount++;
  } elsif (/UDP Source port\:\s+\d+\s+Destination port\: 5169/i) {
    (/\d+\s+(\d+.\d+.\d+.\d+)\s\-\>/);
    $data->{$1}->{'5169'}++;$pilotcount++;
  }
}
print "...done\n";
if ($ipfixcount && $pilotcount) {
  foreach my $src (keys %{$data}) {
  print color 'bold green';
    print "Recevied $data->{$src}->{'4000'} IPFIX records from $src -- OK \n" if $data->{$src}->{'4000'};
    print "Recevied $data->{$src}->{'5169'} PILOT records from $src -- OK \n" if $data->{$src}->{'5169'};
  }
} else {
  print color 'bold red';
  print "No data received from any source - FAILED CHECK!!!\n";
}
print color 'reset';
print "  =============================================================================\n";
# Clean up tethereal's mess
my $res=`rm -f /tmp/etherXX*`;

