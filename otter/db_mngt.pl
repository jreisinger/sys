#!/usr/bin/perl
# Database management example using SQLite
use strict;
use warnings;
use DBI;

my $dbfile = '/tmp/test.db';

# Connect to DB and receive connection handle
my $dbh = DBI->connect( "DBI:SQLite:dbname=$dbfile", "", "" );
$dbh->{RaiseError} = 1;    # do this, or check every call for errors

# Populate the database
$dbh->do(q{CREATE TABLE hosts (name varchar(15), ipaddr varchar(15))});
$dbh->do(q{INSERT INTO hosts VALUES ('albert', '192.168.1.10')});
$dbh->do(q{INSERT INTO hosts VALUES ('blade', '192.168.1.11')});
$dbh->do(q{INSERT INTO hosts VALUES ('notebook', '192.168.1.51')});

# Retrieve SELECT results
my $all = $dbh->selectall_arrayref(q{SELECT * FROM hosts});
foreach my $row (@$all) {
    my ( $name, $ipaddr ) = @$row;
    printf "%-15s %15s\n", $name, $ipaddr;
}

# Close the connection
$dbh->disconnect;

unlink $dbfile;

__END__

More info

* https://metacpan.org/module/DBI
* https://metacpan.org/module/DBD::SQLite
* http://www.sqlite.org
