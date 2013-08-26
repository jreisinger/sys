#!/usr/bin/env perl -w
# List running processes by manually inspecting /proc.
# Shoud be run as root/sudo.
use strict;

opendir my $PROC, '/proc' or die "$!";
while ( readdir $PROC ) {
    next unless /^\d+$/;    # skip non-process dirs
    my $pid     = $_;
    my $cmdline = `cat /proc/$_/cmdline`;
    my $user    = getpwuid( ( lstat "/proc/$pid" )[4] );
    printf "%s %s %s\n", $pid, $user, $cmdline;
}
close $PROC;
