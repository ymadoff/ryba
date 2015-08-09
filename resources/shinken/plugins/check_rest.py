#!/usr/bin/env python2.7

import sys
import requests
from requests_kerberos import HTTPKerberosAuth
from optparse import OptionParser
import subprocess
import re

# Exit statuses recognized by Nagios and thus by Shinken
OK = 0
WARN = 1
CRITICAL = 2
UNKNOWN = 3

def quit(status, text):
    if status is OK:
	print 'OK: '+text
    elif status is WARN:
        print 'WARN: '+text
    elif status is CRITICAL:
	print 'CRITICAL: '+text
    else:
        print 'UNKNOWN: '+text
    	sys.exit(UNKNOWN)
    sys.exit(status)

def build_url(options):
    if options.url:
        return options.url
    else:
        url='http'
        if options.ssl: url+='s'
        url+='://'+options.hostname+':'+str(options.portnum)+options.path
        return url

def www_auth(response):
    auth_fields = {}
    for field in response.headers.get("www-authenticate", "").split(","):
        kind, __, details = field.strip().partition(" ")
        auth_fields[kind.lower()] = details.strip()
    return auth_fields

requests.packages.urllib3.disable_warnings()

## PARAMETERS

parser = OptionParser()
parser.add_option('-H', '--hostname', dest='hostname', default='localhost', help='Hostname of server. Can be FQDN or IP address')
parser.add_option('-p', '--portnumber', dest='portnum', default=80, type='int', help='Port to use. Default is 80')
parser.add_option('-s', '--ssl', action='store_true', dest='ssl', default=False, help='if flagged, will use https')
parser.add_option('-k', '--insecure', dest='secure', action='store_false', default=True, help='Ignore certificate check for HTTPS')
parser.add_option('-n', '--negotiate', dest='negotiate', action='store_true', default=False, help='Enable Kerberos through SPNEGO negotiation')
parser.add_option('-K', '--principal', dest='principal', help='client principal. If specified, will kinit. Need additional keytab path or password')
parser.add_option('-T', '--keytab', dest='keytab', help='path to Kerberos client keytab')
parser.add_option('-W', '--password', dest='password', help='Kerberos client password')
parser.add_option('-P', '--path', dest='path', default='/', help='Path to request. Default is /')
parser.add_option('-u', '--url', dest='url', help='Overwrite URL to request. Default is http(s)://$HOSTNAME$:$PORT$$PATH$')
parser.add_option('-w', '--warning', dest='warn', type='float', default=5.0, help='warning request time. Ignored if using RegExp. Default 1sec')
parser.add_option('-c', '--critical', dest='critical', type='float', default=10.0, help='critical request time. Ignored if using RexExp. Default 10 sec')
parser.add_option('--co', '--contains_ok', dest='contains_ok', help='OK status if response contains it')
parser.add_option('--cw', '--contains_warn', dest='contains_warn', help='WARNING status if response contains it. Ignored if not using contains_ok')
parser.add_option('--cc', '--contains_crit', dest='contains_crit', help='CRITICAL status if response contains it. Anything by default if contains_ok is defined')
parser.add_option('--ro', '--regex_ok', dest='regex_ok', help='OK status if request body matches')
parser.add_option('--rw', '--regex_warn', dest='regex_warn', help='WARNING status if request body matches. Ignored if not using regex_ok')
parser.add_option('--rc', '--regex_crit', dest='regex_crit', help='CRITICAL status if request body matches. Anything by default if regex_ok is defined')

options, args = parser.parse_args()

## MAIN CODE

if options.principal:
    if options.keytab:
        kinit = subprocess.Popen(['/usr/bin/kinit', options.principal, '-kt', options.keytab])
    elif options.password:
        kinit = subprocess.Popen(['/usr/bin/kinit', options.principal], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        kinit.communicate(options.password)
    else:
        quit(CRITICAL,'Please specify password or keytab if client principal is specified')
try:
    kauth = HTTPKerberosAuth() if options.negotiate else None
    r = requests.get(build_url(options), auth=kauth, verify=options.secure)
except:
    quit(CRITICAL,'Unexpected error '+str(sys.exc_info()[0]))

if r.status_code >= 401:
    quit(CRITICAL,'Server returned '+str(r.status_code))
# Text SEARCH
if options.contains_ok:
    if r.text.find(options.contains_ok) > 0: quit (OK, 'response contains '+options.contains_ok)
    elif options.contains_warn and r.text.find(options.contains_warn) > 0: quit(OK, 'response contains '+options.contains_warn)
    elif options.contains_crit:
        if r.text.find(options.contains_crit) > 0: quit(CRITICAL, 'response contains '+options.contains_crit)
	else: quit(UNKNOWN, 'response doesn\'t contain any specified text')
    else: quit(CRITICAL, 'response doesn\'t contain any specified text')
# Text Pattern Match
if options.regex_ok:
    if re.match(options.regex_ok,r.text): quit(OK, 'response matches '+options.regex_ok)
    elif options.regex_warn and re.match(options.regex_warn,r.text): quit(WARN, 'response matches '+options.regex_warn)
    elif options.regex_crit:
        if re.match(options.regex_crit,r.text): quit(CRITICAL, 'response matches '+options.regex_crit)
        else: quit(UNKNOWN, 'response doesn\'t match any specified regex')
    else: quit(CRITICAL, 'response doesn\'t match any specified regex')
# Default, Elapsed Time only
elapsed = r.elapsed.total_seconds()
if elapsed < options.warn:
    quit(OK,'request time: '+str(elapsed)+'s'+r.text)
elif elapsed < options.critical:
    quit(WARN,'request time > '+str(options.warn)+':'+str(elapsed)+'s')
else:
    quit(CRITICAL,'request time > '+str(options.critical)+':'+str(elapsed)+'s')
