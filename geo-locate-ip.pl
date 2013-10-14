#!/usr/bin/perl
# Parse fail2ban logs and geolocate IP addresses of attackers.
use strict;
use warnings;
use Geo::IP;
use IO::Uncompress::Gunzip qw($GunzipError);
use DBI;

#
# Gather IP addresses from log files
#
my %ips;
for my $log_file ( glob "/var/log/fail2ban.log*" ) {

    my $fh;
    if ( $log_file =~ /\.gz$/ ) {    # .gz file
        $fh = new IO::Uncompress::Gunzip $log_file
          or die "IO::Uncompress::Gunzip failed: $GunzipError\n";
    } else {                         # plain text file
        open $fh, "<", $log_file or die "Can't read '$log_file': $!\n";
    }

    while ( $_ = <$fh> ) {
        my ( $date, $time, $ip ) = $_ =~ /^
                        (\d{4}-\d{2}-\d{2})\s       # date: 2013-10-14
                        (\d{2}:\d{2}:\d{2},\d{3})\s # time: 14:02:57,114
                        .*Ban\s([\d\.]+)            # IP address
                       $/x;
        push @{ $ips{"$date $time"} }, $ip if $ip;
    }
    close $fh;
}

#
# Store data to database
#
my $dbfile     = '/tmp/test.db';
my $table_name = 'attacks';

# Connect to DB and receive connection handle
my $dbh = DBI->connect( "DBI:SQLite:dbname=$dbfile", "", "" );
$dbh->{RaiseError} = 1;    # do this, or check every call for errors

# Create table if it doesn't already exists
my $sth = $dbh->prepare(
    q{SELECT name FROM sqlite_master WHERE type='table' AND name=?});
$sth->execute($table_name);
my $all = $sth->fetch;     # aref

# PRIMARY KEY is needed for REPLACE (below) to work
$dbh->do(
    qq{CREATE TABLE $table_name (timestamp varchar(23), ipaddr
    varchar(15), country varchar, PRIMARY KEY(timestamp, ipaddr))}
) if not defined @$all;

# Populate the table
my $gi = Geo::IP->new(GEOIP_MEMORY_CACHE);
for my $timestamp ( sort keys %ips ) {
    for my $ip ( @{ $ips{$timestamp} } ) {
        my $country = $gi->country_name_by_addr($ip) // 'unknown';
        $sth = $dbh->prepare(
            qq{REPLACE INTO $table_name (timestamp, ipaddr, country)
            VALUES (?, ?, ?)}
        );
        $sth->execute( $timestamp, $ip, $country );

    }

}

#
# Count frequencies of countries
#
$sth = $dbh->prepare(qq(SELECT * FROM $table_name));
$sth->execute;
$all = $sth->fetchall_arrayref;
my %attack_freq;
for my $rowref (@$all) {
    my $country = $rowref->[2];
    $attack_freq{$country}++;
}

#
# Print out text report
#
for my $country ( sort { $attack_freq{$b} <=> $attack_freq{$a} } keys %attack_freq ) {
    print "$country: $attack_freq{$country}\n";
}
