#!/usr/bin/env python
import paramiko
import argparse
from pprint import pprint # like Data::Dumper
import smtplib
from email.mime.text import MIMEText
import getpass
import pickle
import os

def checks():
    """Checks to be run on remote hosts. Checks output OK or FAIL. run_checks() handles the errors of the checks themselves."""

    checks = {
        # FAIL if ntpd process is not running
        'ntpd':    """ps aux | perl -lne '$found=1 if /\\bntpd\\b/; END { print $found ? "OK" : "FAIL" }'""",

        # FAIL if splunkd process is not running
        'splunk':    """ps aux | perl -lne '$found=1 if /\\bsplunkd\\b/; END { print $found ? "OK" : "FAIL" }'""",

        # FAIL if syslog-ng process is not running
        'syslog-ng': """ps aux | perl -lne '$found=1 if /\\bsyslog-ng\\b/; END { print $found ? "OK" : "FAIL" }'""",

        # FAIL if any partition is used for over 90 %
        'disk':      """df -hP | perl -lne '/^\// or next; ($use,$mount) = (split)[4,5]; push @full, $mount if $use > 90; END { print @full ? "FAIL @full" : "OK" }'""",

        # FAIL if uptime is less than 259 200 seconds (3 days)
        'uptime':    """perl -lane 'print $F[0] > 259_200 ? "OK" : "FAIL"' /proc/uptime""",

        # FAIL if load (last 5 min) is more than 15
        'load':     """perl -lane 'print $F[0] < 15 ? "OK" : "FAIL"' /proc/loadavg"""
    }

    return checks

def parse_args():
    """Parse command line options and arguments"""

    parser = argparse.ArgumentParser(description='Basic monitoring of remote hosts. The output format is HOST | CHECK | STATUS | [INFO]. If there is a problem with a checked feature (CHECK) status is FAIL. If the check itself fails status is ERROR.')
    parser.add_argument('--file', type=argparse.FileType('r'), required=True,
                        help='file containing remote hosts; one host per line',)
    parser.add_argument('--user', type=str, default=getpass.getuser(),
                        help='SSH username; default is the current username',)
    parser.add_argument('--key', type=str,
                        help='SSH private key',)
    parser.add_argument('--port', type=int, default=22,
                        help='SSH network port; default is 22',)
    parser.add_argument('--verbose', action='store_true',
                        help='print what you are doing',)
    parser.add_argument('--nomail', action='store_true',
                        help='print fails to STDOUT instead of sending via email',)
    parser.add_argument('--nocheck', nargs='+',
                        help='do not run these checks',)

    return parser.parse_args()

def run_checks(hosts):
    """Execute check on hosts."""

    #paramiko.util.log_to_file('paramiko.log')
    s = paramiko.SSHClient()
    s.load_system_host_keys()

    fails = []

    for host in hosts:
        s.connect(host, parse_args().port, parse_args().user, key_filename=parse_args().key)
        for name, cmd in checks().iteritems():

            # skip some checks defined on the commandline?
            if parse_args().nocheck and filter(lambda check: name == check, parse_args().nocheck):
                continue

            stdin, stdout, stderr = s.exec_command(cmd)

            # if the check itself fails it outputs ERROR
            err = stderr.read().rstrip()
            if err:
                if args.verbose:
                    print " | ".join([ host, name, 'ERROR', err ])
                fails.append( { 'host': host, 'check': name, 'status': 'ERROR', 'msg': err } )
                continue  # like next in Perl

            output = stdout.read().rstrip()
            words = output.split()
            status = words[0]
            msg = "".join(words[1:])
            if args.verbose:
                print " | ".join([ host, name, status, msg ])
            if status != 'OK':
                fails.append( { 'host': host, 'check': name, 'status': status, 'msg': msg } )

        s.close()

    return fails    # array of dictionaries

def send_email(fails):
    """If we have some failed checks send them via email"""

    sender = 'monitor'
    recipients = [ 'john.smith@example.com', 'jane.doe@example.com' ]
    subject = 'system monitor'

    body = format_fails(fails)

    if not body:
        return

    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = ", ".join(recipients)
    s = smtplib.SMTP('localhost')
    s.sendmail(sender, recipients, msg.as_string())
    s.quit()

def format_fails(fails):
    """Prepare info about fails to be printed out or emailed"""

    output = ""
    for item in fails:
        output = output + " | ".join([item['host'], item['check'], item['status'], item['msg']]) + "\n\n"

    return output

def seen(filename, fails):
    """Have we already seen these fails?"""

    hosts_file = os.path.splitext(os.path.basename(filename))[0]
    data_file = ".".join( [ "monitor", hosts_file, "data" ] )

    seen = False

    if os.path.isfile(data_file):
        prev_fails = pickle.load( open( data_file, "rb" ) )
        if fails == prev_fails:
            seen = True
    pickle.dump( fails, open( data_file, "wb" ) )

    return seen

if __name__ == "__main__":

    args = parse_args()
    hosts = args.file.read().splitlines()   # remove newlines
    fails = run_checks(hosts)

    #pprint(fails)

    if parse_args().nomail:
        if seen(args.file.name, fails):
            print "NOTE: we've already seen these fails"
        print(format_fails(fails))
    elif not seen(args.file.name, fails):
        send_email(fails)
