#!/usr/bin/perl -w
# Show all open files and PIDs using them.
use strict;
use Text::Wrap;

my $lsofexec = '/usr/bin/lsof';

# (F)ield mode, NUL (0) delim, show (L)ogin, file (t)ype and file (n)ame
my $lsofflags = '-F0Ltn';

my ( $pid, $login, $type, $pathname, %seen, %paths );

open my $LSOFPIPE, '-|', "$lsofexec $lsofflags" or die "$!";
while ( my $lsof = <$LSOFPIPE> ) {

    # deal with a process set
    if ( substr( $lsof, 0, 1 ) eq 'p' ) {
        ( $pid, $login ) = split /\0/, $lsof;
    }

    # deal with a file set; note: we are only interested
    # in "regular" files (as per Solaris and Linux, lsof on other
    # systems may mark files and directories differently)
    if (
        substr( $lsof, 0, 5 ) eq 'tVREG' or    # Solaris
        substr( $lsof, 0, 4 ) eq 'tREG'        # Linux
      )
    {
        ( $type, $pathname ) = split( /\0/, $lsof );

        # a process may have the same pathname open twice;
        # these two lines make sure we only record it once
        next if ( defined $seen{$pathname} and $seen{$pathname} eq $pid );
        $seen{$pathname} = $pid;
        push( @{ $paths{$pathname} }, $pid );
    }

}
close $LSOFPIPE;

foreach my $path ( sort keys %paths ) {
    print "$path:\n";
    print wrap( "\t", "\t", join( " ", @{ $paths{$path} } ) ), "\n";
}

