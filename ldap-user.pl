#!/usr/bin/perl
# Create LDIF file for Unix user.
use strict;
use warnings;

die "Usage: $0 name surname uid gid\n" unless @ARGV == 4;

my($name, $surname, $uid, $gid) = @ARGV;
my $login = (split //, $name)[0] . $surname;

print << "END"
dn: uid=$login,ou=people,dc=company,dc=com
uid: $login
uidNumber: $uid
gidNumber: $gid
cn: \u$name
sn: \u$surname
displayName: \u$name\u$surname
mail: $name.$surname\@company.com
objectClass: top
objectClass: person
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
loginShell: /bin/bash
homeDirectory: /home/$login
END
