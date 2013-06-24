#!/usr/bin/perl
# Parse fail2ban logs and geolocate IP addresses of attackers.
use strict;
use warnings;
use Geo::IP;
use IO::Uncompress::Gunzip qw($GunzipError);

#
# Gather IP addresses from log files
#
my %country;
for my $log_file ( glob "/var/log/fail2ban.log*" )
{

    my $fh;
    if ( $log_file =~ /\.gz$/ )
    {    # .gz file
        $fh = new IO::Uncompress::Gunzip $log_file
          or die "IO::Uncompress::Gunzip failed: $GunzipError\n";
    }
    else
    {    # plain text file
        open $fh, "<", $log_file or die "Can't read '$log_file': $!\n";
    }

    while ( $_ = <$fh> )
    {
        my $ip = $1 if /an ([\d\.]+)$/;
        $country{$ip} = 1 if $ip;
    }
    close $fh;
}

#
# Count frequencies of countries
#
my %freq;
my $unknown = 0;
for my $ip ( keys %country )
{
    my $gi = Geo::IP->new(GEOIP_MEMORY_CACHE);

    # returns undef if country is unallocated, or not defined in our database
    my $country = $gi->country_code_by_addr($ip);
    if ( not $country )
    {
        $unknown++;
        next;
    }
    push @{ $freq{$country} }, $ip;
}

#
# Print out report
#
my $total = keys %country;
for my $country ( sort { @{ $freq{$b} } <=> @{ $freq{$a} } } keys %freq )
{
    my $num = @{ $freq{$country} };
    my $perc = sprintf "%d", $num / $total * 100;
    print "$country -- $num ($perc %)\n";
    print "    $_\n" for @{ $freq{$country} };
}
print "Unknown countries -- " . $unknown . "\n";
