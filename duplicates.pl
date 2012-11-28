#!/usr/bin/perl
# Find files that might be duplicates.
# If you want to remove the duplicated files, ensure that you have a backup!
use warnings;
use strict;
use 5.010;
use Digest::MD5;

die "Usage: $0 file(s)\n" unless @ARGV >= 1;

my( %file, %duplicate );
while ( my $file = shift ) {
    next unless -f $file;   # skip directories
    unless ( open(FILE, $file) ) {
        warn "Can't open '$file': $!";
        next;
    }
    binmode(FILE);

    my $hash = Digest::MD5->new->addfile(*FILE)->hexdigest;
    # key of %duplicte is a dereferenced anonymous array
    push @{$duplicate{$hash}}, $file;
    close FILE;
}

for my $hash ( sort keys %duplicate ) {
    if ( @{$duplicate{$hash}} > 1 ) {
        say "$hash", "\t", join( ', ', @{$duplicate{$hash}} );
    }
}

__END__
# Similar stuff in shell - it's much faster with many/big files
md5sum.exe /etc/* 2>&1 | grep -v 'Is a directory' | sort -k1 | awk '{ print $1 \
    }' | uniq -c | sort

