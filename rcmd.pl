#!/usr/bin/perl -s
# source: https://github.com/jreisinger/sys/blob/master/rcmd
use strict;
use warnings;
#use lib "$ENV{HOME}/perl5/lib";
use Net::OpenSSH;
use Term::ANSIColor qw(:constants);

# command line options
our ($h, $v, $l, $u, $k);

# help message
my $desc = <<"EOF";
Execute a command on remote hosts over SSH. FILE is a file containing hostnames
of IP addresses of remote hosts. Use - instead of FILE to get hosts from the
STDIN. COMMAND is either supplied by you (ex. 'df -h | grep /home') or it's one
of the built-in commands.
EOF
my $usage = <<"EOF";
$0 [-u=USER -k=KEY -v] FILE 'COMMAND'
$0 -l [-v]
$0 -h
  -u=USER   SSH username; default is the current username
  -k=KEY    SSH private key; ex. /home/foo/.ssh/id_rsa
  -v        be more verbose
  -l        list built-in commands and exit
  -h        print help and exit
EOF

# print help and exit
if ($h) {
    print "$desc\n$usage";
    exit;
}

my $private_key_path = $k || "";

# put built-in commands into a hash
my %Builtins;
while (<DATA>) {
    my ($name, $cmd) = split ' ', $_, 2;
    $Builtins{$name} = $cmd;
}

# list built-in commands and exit
if ($l) {
    for my $name (sort keys %Builtins) {
        if ($v) { # verbose
            print GREEN, "$name", RESET, " --> $Builtins{$name}";
        } else {  # just names
            print "$name\n";
        }
    }

    exit;
}

# check and get command line arguments
@ARGV == 2 or die $usage;
my ( $hosts, $cmd ) = @ARGV;
my $contents = do { local ( @ARGV, $/ ) = $hosts; <> };
my @hosts = split ' ', $contents;

# username to use for ssh connections
my $user;
if ($u) {
    $user = $u;
} else {
    $user = getlogin || getpwuid($<) || die "Can't get current username";
}

# multiple connections are established (in parallel)
my %ssh;
for my $host (@hosts) {
    $ssh{$host} = Net::OpenSSH->new(
        $host,
        user    => $user,
        key_path => $private_key_path,
        async   => 1,
        timeout => 3,
        master_stderr_discard => 1,  # don't show the MOTD
    );
}

# run a command on all the hosts (sequentially) ...
for my $host (@hosts) {

    # if the supplied command is a name of a built-in command run that one
    $cmd = $Builtins{$cmd} if exists $Builtins{$cmd};

    my $msg = "## $host";
    $msg .= ": $cmd" if $v;
    print GREEN, "$msg\n", RESET;
    $ssh{$host}->system($cmd);
}

__DATA__
boot_time           last | grep boot | head -1 | perl -lane 'print join " ", @F[4..7]'
big_palindromes     perl -lne 'print if $_ eq reverse and length >= 5' /usr/share/dict/words
free_mem            free -m | grep -E '^Mem:' | perl -lane '($total,$free,$buffers,$cached) = ( /(\d+)/g )[0,2,4,5]; printf "%.0f%%\n", ($free+$buffers+$cached)/$total*100'
cpu_info            lscpu | perl -0777 -ne '$ncpu=$1 if /^CPU\(s\):\s*(\d+)/m; $mhz=$1 if /^CPU MHz:\s*([\d\.]+)/m; END { printf "%s x %.0fMHz\n", $ncpu, $mhz }'
mem_info            cat /proc/meminfo | perl -ne 'printf "%.0fMB\n", $1/1000 if /^MemTotal:\s*(\d+)/'
