#!/usr/bin/env python2.7

import sys
import requests
from requests_kerberos import HTTPKerberosAuth
from optparse import OptionParser
import subprocess
import json

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
        url+='://'+options.hostname+':'+str(options.portnum)+'/jmx?qry=Hadoop:service=DataNode,name=FSDatasetState-*'
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
parser.add_option('-s', '--ssl', action='store_true', dest='ssl', default=False, help='If flagged, will use https')
parser.add_option('-k', '--insecure', dest='secure', action='store_false', default=True, help='Ignore certificate check for HTTPS')
parser.add_option('-n', '--negotiate', dest='negotiate', action='store_true', default=False, help='Enable Kerberos through SPNEGO negotiation')
parser.add_option('-K', '--principal', dest='principal', help='Client principal. If specified, will kinit. Need additional keytab path or password')
parser.add_option('-T', '--keytab', dest='keytab', help='Path to Kerberos client keytab')
parser.add_option('-W', '--password', dest='password', help='Kerberos client password')
parser.add_option('-u', '--url', dest='url', help='Overwrite URL to request. Default is http(s)://$HOSTNAME$:$PORT$$PATH$')
parser.add_option('-w', '--warning', dest='warn', help='Warning level. Percent or Bytes')
parser.add_option('-c', '--critical', dest='critical', default=10.0, help='Critical level. Percent or Bytes')

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
    ret = json.loads(r.text).get('beans')[0]
except:
    quit(CRITICAL,'Unexpected error '+str(sys.exc_info()[0]))

if r.status_code >= 401:
    quit(CRITICAL,'Server returned '+str(r.status_code))

capacity = ret.get('Capacity')
used = ret.get('DfsUsed')

warn = (float(options.warn[:-1])*capacity)/100 if options.warn.endswith('%') else float(options.warn)
crit = (float(options.critical[:-1])*capacity)/100 if options.critical.endswith('%') else float(options.critical)
if used >= crit: quit(CRITICAL, str(used*100.0/capacity)+'%')
elif used >= warn: quit(WARN,  str(used*100.0/capacity)+'%')
else: quit(OK, str(used*100.0/capacity)+'%')
