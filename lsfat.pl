#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use autodie;
use Getopt::Long;
use Pod::Usage;
use File::Find;

my $help = 0;
my $top  = 10;
my $fs;
GetOptions(
    "h|?|help" => \$help,
    "f|fs=s"   => \$fs,
    "top=i"    => \$top,
) or pod2usage(1);

pod2usage( -exitval => 0, -verbose => 2, -noperldoc => 1 ) if $help;

#die "You're not root, exiting ...\n" unless $< == 0;

if ($fs) {
    my $files = get_fat_files( $fs, $top );

    # Find the longest filename
    my @filenames = map { $_->{name} } @$files;
    my $max_len = max_len(\@filenames);

    print "### The fattest files:\n";
    for my $file (@$files) {
        printf "%-${max_len}s %s\n", $file->{name}, scaleIt($file->{size});
    }
} else {
    my @fs = get_fat_fs($top);

    # Find the longest filesystem name
    my @fs_names = map { $_->[0] } @fs;
    my $max_len = max_len(\@fs_names);

    print "### The fattest file systems:\n";
    for my $fs (@fs) {
        printf "%-${max_len}s %d%%\n", $fs->[0], $fs->[1];
    }
}

# Return the size of the longest string from a list of strings
sub max_len {
    my $aref = shift;
    my $max_len = 0;
    for my $string (@$aref) {
        my $len = length($string);
        $max_len = $len if $len > $max_len;
    }
    return $max_len;
}

sub scaleIt {
    my $size_in_bytes = shift;

    return unless defined $size_in_bytes;

    my ( $size, $n ) = ( $size_in_bytes, 0 );
    ++$n and $size /= 1024 until $size < 1024;
    return sprintf "%.0f%s", $size, (qw[ B KB MB GB TB ])[$n];
}

sub get_fat_files {
    my $fs  = shift;
    my $top = shift;    # number of fattest files to return
    return unless $fs;

    my @files;

    find(
        sub {
            return unless -f;
            my $size = -s _;
            my $name = $File::Find::name;
            push @files, { size => $size, name => $name };
        },
        $fs
    );

    my @top_files;

    my $count = 1;
    for my $file ( reverse sort { $a->{size} <=> $b->{size} } @files ) {
        last if $count++ > $top;
        push @top_files, $file;
    }

    return \@top_files; # AoH
}

sub get_fat_fs {
    my $top = shift // 3;    # number of fattest filesystems to collect

    my %usage;

    for (`df -P`) {
        chomp;
        next unless /^\s*\//;
        my ( $fs, $percentage ) = (split)[ 5, 4 ];
        ( $usage{$fs} ) = $percentage =~ /(\d+)/;
    }

    my @top_usage;
    my $i = 0;
    for my $fs ( sort { $usage{$b} <=> $usage{$a} } keys %usage ) {
        last if $i++ >= $top;
        push @top_usage, [ $fs, $usage{$fs} ];
    }

    return @top_usage;
}

__END__

=head1 NAME

lsfat - list biggest file systems or files

=head1 SYNOPSIS

lsfat [options]

  options:
    -h, -?, --help  brief help message
    --fs FILESYSTEM search FILESYSTEM for big files
    --top N         show N biggest filesystems/files (default 10)

=head1 EXAMPLES

Find top 3 biggest files on root filesystem:

    lsfat --fs / --top 3

=cut
