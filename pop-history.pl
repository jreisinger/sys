#!/usr/bin/perl
# Read the history of shell commands and determine which ones you use the most.
#
# In bash, you can set the HISTFILE and HISTFILESIZE to control history‘s
# behavior. To get the commands to count, you can read the right file or shell
# out to the history command.
use strict;
use warnings;
use 5.010;
use autodie;
use File::Basename;

my $hist_file = "$ENV{HOME}/.bash_history";
open my $hf, "<", $hist_file;

my %count;
for (<$hf>) {
    my $cmd = (split)[0];
    $cmd = basename $cmd if $cmd and $cmd =~ /\//;
    $count{$cmd}++ if $cmd;
}

say "$_: $count{$_}" for sort { $count{$b} <=> $count{$a} } keys %count;
