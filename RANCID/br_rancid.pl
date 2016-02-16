#!/usr/bin/perl

#use warnings;

use Data::Dumper;

#$dir="./config-test";
#$dir="./config-dir-current";
$dir=$ARGV[1];

$if_index_file=$ARGV[0];

$count=@ARGV;


sub USAGE {

    print "Usage : \n";
    print "---------------------------------------------------------------\n";
    print "./br_rancid.pl <ifindex File> <routers directory> \n\n";    
    print "example ./br_rancid.pl ifindex.list.guavus /data/routers/config \n";
    print "---------------------------------------------------------------\n";
    exit;
}

if($ARGV[0] eq '--help' || $count != 2){

    &USAGE;

}

open(OUT,'>','output.csv') || die $!;

## RouterType,RouterName,ifindex,ifname,Description,,Sampled,Status,ParentRouter

my $ifindex={};

open(INF,$if_index_file) || die $!;

while($if=<INF>){
    chomp($if);
    @val=split(/,/,$if);
    $rout=$val[0];
    $num=$val[1];
    $int=$val[2];
    $ifindex{$rout}{$int}=$num;
}

#print Dumper \%ifindex;
close(INF);
#exit;

sub CISCO {
    
    my $type="CISCO";
    my $file_in=shift;
    my @tmp_r = split(/_/,$file_in);
    my $rout_name=$tmp_r[0];
    my $desc;
    my $interface;
    my $ingress,
    my $egress;
    my $direction;
    my $state;
    open(IN,"$dir/$file_in") || die $!;

    @line=<IN>;
    close(IN);
    #print "@line\n";
    #@line = map { s/^\s+//g; $_;} @line;
    foreach $i (0..$#line){

        $interface="";$desc="";$ingress="";$egress="";$direction="";$state="Active";
        chomp($line[$i]);
        if($line[$i]=~/^ interface/){
            @int_array=split(/\s/,$line[$i]);
            $interface=$int_array[$#int_array];
            #print "INTERFACE $interface, ROUTER $rout_name, SNMPID $snmp_id","\n";
            while($line[$i] !~ /^ !/){
            #while($line[$i+1] !~ /^interface/){
                #exit if eof;
                if($line[$i]=~/^  description/){
                    #print $line[$i],"\n";
                    @tmp=split(/description/,$line[$i]);
                    $desc=$tmp[$#tmp];
                    $desc =~ s/^\s+//g;
                    chomp($desc);
                    #print "DESC $desc\n";
                }
                if($line[$i]=~/ingress/){
                    #$ingress="ingress";
                    $ingress="Ingress";
                }
                if($line[$i]=~/egress/){
                    #$egress="egress";
                    $egress="Egress";
                }

                if($line[$i]=~/shutdown/){

                    $state="Shutdown";

                }
                
                $i++;

            }
            $snmp_id=$ifindex{$rout_name}{$interface};
            if($interface && $desc){
                    
                if($ingress && $egress){
                    $direction="bidirectional";
                    print OUT "$type,$rout_name,$snmp_id,$interface,$desc,$direction,$state\n";
                 }elsif($ingress){
                    print OUT "$type,$rout_name,$snmp_id,$interface,$desc,$ingress,$state\n";
                 }elsif($egress){
                    print OUT "$type,$rout_name,$snmp_id,$interface,$desc,$egress,$state\n";
                 }else{print OUT "$type,$rout_name,$snmp_id,$interface,$desc,No,$state\n";}
    
                }

        }else { next; }

    }

}

sub JUNIPER {
    my $type="JUNIPER";
    my $file_in=shift;
    my @tmp_r = split(/_/,$file_in);
    my $rout_name=$tmp_r[0];
    my $desc;
    my $interface;
    my $direction;

    open(INJ,"$dir/$file_in") || die $!;

    @line=<INJ>;
    close(INJ);
    @line = map { s/^\s}/     }/g; $_;} @line;
    foreach $i (0..$#line){
        $interface="";$desc="";$direction="";$input="";$output="";$parent="";$state="Active";
        chomp($line[$i]);
        if($line[$i]=~/^         description/){
            @int_array=split(/description/,$line[$i]);
            $desc=$int_array[$#int_array];
            $desc =~ s/;//g;
            chomp($desc);
            $tmp_interface=$line[$i - 1];
            $tmp_interface =~ s/\s+//g;
            $tmp_interface =~ s/\{//g;
            chomp($tmp_interface);
            while($line[$i] !~ /^     }/)
            {
                if($line[$i]=~/unit/)
                {
                    @tmp=split(/unit/,$line[$i]);
                    $units=$tmp[1];
                    $units =~ s/^\s+//g;
                    $units =~ s/\{//g;
                    chomp($units);
                    $interface="$tmp_interface\.$units";
                    chomp($interface);
                    #print "DESC $desc\n";
                }

                if($line[$i]=~/^                     input/ || $line[$i]=~/^                     input-list/)
                {
                    @tmp_input=split(/\s/,$line[$i]);
                    $input=$tmp_input[$#tmp_input];
                    $input=~s/;//g;
                }

                if($line[$i]=~/^                     output/)
                {
                    @tmp_output=split(/\s/,$line[$i]);
                    $output=$tmp_input[$#tmp_input];
                    $output=~s/;//g;
                }

                if($line[$i]=~/                 ^address/)
                {
                    @tmp_add=split(/\s/,$kine[$i]);
                    $add=$tmp_add[$#tmp_add];
                    $add=~s/;//g;
                }
                if($line[$i] =~ /802.3ad/){

                    @tmp_parent=split(/\s/,$line[$i]);
                    $parent=$tmp_parent[$#tmp_parent];
                    $parent=~s/;//g;
                }
                if($line[$i]=~/shutdown/){

                    $state="Shutdown";

                }
                $i++;

            }
                if($interface)
                {   
                    $final_interface=$interface;
                    chomp($final_interface);
                    $final_interface=~s/\s//g;
                }else{$final_interface=$tmp_interface;chomp($final_interface);$final_interface=~s/\s//g;}

                $snmp_id=$ifindex{$rout_name}{$final_interface};
            
                if($final_interface && $desc)
                {    
                    if($input && $output)
                    {
                        $direction="bidirectional";
                        print OUT "$type,$rout_name,$snmp_id,$final_interface,$desc,$direction,$state,$parent\n";
                    }elsif($input){
                        print OUT "$type,$rout_name,$snmp_id,$final_interface,$desc,ingress,$state,$parent\n";}
                    elsif($output){
                        print OUT "$type,$rout_name,$snmp_id,$final_interface,$desc,outgress,$state,$parent\n";}
                    else{
                        print OUT "$type,$rout_name,$snmp_id,$final_interface,$desc,NO Direction,$state,$parent\n";}  

                }
        }
    } 
}

opendir (DIR,$dir) || die $!;

while ($file = readdir(DIR)){
    next if ($file =~ m/^\./);
    if($file =~ /cisco/){
        &CISCO($file);

    }
    else
    {
        &JUNIPER($file);
    }
 
}

close(DIR);

