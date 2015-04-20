#!/usr/bin/perl 

use strict;
use warnings;
use Term::ANSIColor;
use lib "../lib";
use Net::Hadoop::DFSAdmin::ReportParser;
my ($status,$datanode,$capacity,$used,$free,$availnodes,$numnodes,$deadnodes,$currcap,$totalcap,$usedcap,$pcusedcap,$remcap,$pcremcap,$corruptblocks);

open(my $fh, '-|', 'hadoop', 'dfsadmin', '-report')
  or die "failed to execute 'hadoop dfsadmin -report'";
my @lines = <$fh>;
close($fh);
my $r = Net::Hadoop::DFSAdmin::ReportParser->parse(@lines);
my $err=0;
select (STDOUT);
$~="HadoopReport";
$^="HadoopReport_TOP";
foreach (@{$r->{'datanodes'}}) {
  ($status,$datanode,$capacity,$used,$free) =
    ($_->{'status'}, $_->{'name'}, $_->{'capacity_configured'}/1024/1024/1024, $_->{'used_percent'}, $_->{'remaining_percent'});
  if ($_->{'status'}!~/normal/i) { $err=1; }
  write();
}
if ( $r->{'blocks_with_corrupt_replicas'} ) { $err=1; }
if ( $r->{'remaining_percent'} < 5.0 ) { $err=1; }
$~="HadoopFooter";
$^='';
($availnodes,$numnodes,$deadnodes,$currcap,$totalcap,$usedcap,$pcusedcap,$remcap,$pcremcap,$corruptblocks) = 
  ($r->{'datanodes_available'}, $r->{'datanodes_num'},$r->{'datanodes_dead'},
   $r->{'capacity_present'}/1024/1024/1024,$r->{'capacity_configured'}/1024/1024/1024,
   $r->{'used'}/1024/1024/1024,$r->{'used_percent'},
   $r->{'remaining'}/1024/1024/1024,$r->{'remaining_percent'},
   $r->{'blocks_with_corrupt_replicas'},
  );
write();
if ($err) { print color 'bold red'; print "\tRESULT : FAIL\n"; print color 'reset'; } 
else { print color 'bold green'; print "\tRESULT : OK\n"; print color 'reset'; }
print "  =============================================================================\n";
# Hadoop DFS Report Format
# ------------------------
format HadoopReport_TOP =
  =============================================================================
  DataNode                     Status           Capacity       Used %    Free %
  =============================================================================
.
format HadoopReport = 
  @<<<<<<<<<<<<<<<<<<<<<<  @||||||||||||||||  @####.### GiB  @##.##%   @##.##%
  $datanode,  $status,  $capacity,  $used,  $free
.
format HadoopFooter = 
  =============================================================================
  DataNodes Available = @>>  of @<<
  $availnodes, $numnodes
  DataNode  Dead      = @>>  of @<<
  $deadnodes, $numnodes
  Total Capacity      =  @#######.### GiB of @#######.### GiB
  $currcap, $totalcap
  Current Usage       =  @#######.### GiB (@##.##% Used)
  $usedcap, $pcusedcap
  Remaining Capacity  =  @#######.### GiB (@##.##% Free)
  $remcap, $pcremcap
  Corrupt Blocks      =  @######
  $corruptblocks
  =============================================================================
.
