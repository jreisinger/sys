#!/bin/bash
# A simple iptables firewall script.
# Usage:
#    Run this script: bash iptables.sh
#    Check rules are ok: iptables -L -n
#    Store them: iptables-save > /etc/iptables.conf
#    Create /etc/network/if-up.d/iptables
#        #!/bin/sh
#        iptables-restore < /etc/iptables.conf
#    Set mode: chmod +x /etc/network/if-up.d/iptables
# Usage 2:
#    Place a call to this script in your local startup script
#        /etc/rc.local - Debian, Ubuntu
#        /etc/rc.d/rc.local - Red Hat, Fedora
#        /etc/init.d/boot.local - OpenSUSE
#        /etc/conf.d/local.start - Gentoo

IPT='/sbin/iptables'

# Flush filter tables chains
$IPT -F INPUT
$IPT -F FORWARD
$IPT -F OUTPUT

# Set the default policy
$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT DROP

# Let traffic on the loopback interface pass
$IPT -A OUTPUT -d 127.0.0.1 -o lo -j ACCEPT
$IPT -A INPUT -s 127.0.0.1 -i lo -j ACCEPT

# Let DNS traffic pass
$IPT -A OUTPUT -p udp --dport 53 -j ACCEPT
$IPT -A INPUT -p udp --sport 53 -j ACCEPT

# Let clients' TCP traffic pass
$IPT -A OUTPUT -p tcp --sport 1024:65535 -m state \
            --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --dport 1024:65535 -m state \
            --state ESTABLISHED,RELATED -j ACCEPT

# Let SSH traffic pass
$IPT -A OUTPUT -p tcp --sport 22 -m state \
            --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --dport 22 -m state \
            --state NEW,ESTABLISHED,RELATED -j ACCEPT
