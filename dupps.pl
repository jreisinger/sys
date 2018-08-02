#!/usr/bin/env perl
#
# Dupps prints PIDs of processes that have the same basename.
#
use 5.014;    # includes strict
use warnings;
use autodie;

use File::Basename;

open my $procs, "-|", "ps aux";

my %pids;
while (<$procs>) {
    next if /^USER/;
    next if /[\][]/;
    my ( $pid, $cmd ) = (split)[ 1, 10 ];
    $cmd = basename($cmd);
    push @{ $pids{$cmd} }, $pid;

    #say $pid, $cmd;
    #print;
}

for my $cmd ( reverse sort { @{ $pids{$a} } <=> @{ $pids{$b} } } keys %pids ) {
    if ( @{ $pids{$cmd} } > 1 ) {
        print scalar( @{ $pids{$cmd} } ), ", $cmd: ",
          join( "|", @{ $pids{$cmd} } ), "\n";
    }
}

#use Data::Dumper;
#print Dumper \%pids;
