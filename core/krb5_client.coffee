
misc = require 'mecano/lib/misc'
# krb = require './krb'
module.exports = []

module.exports.push 'phyla/core/yum'
module.exports.push 'phyla/core/ssh'
module.exports.push 'phyla/core/ntp'
module.exports.push 'phyla/core/openldap_client'

###
Kerberos KDC Client
===================

Usefull client commands:
*   To list all the current principals in the realm: `getprincs`
*   To login: `kadmin -p big/admin@EDF.FR -s big1.big`
*   To print details on a principal: `getprinc host/hadoop1.hadoop@ADALTAS.COM`
*   To examine the content of the /etc/krb5.keytab: `klist -etk /etc/krb5.keytab`
*   To destroy our own tickets: `kdestroy`
*   To get the test.user's ticket: `kinit -p wdavidw@ADALTAS.COM`
*   To confirm that we do indeed have the new ticket: `klist`
*   Check krb5kdc is listening: `netstat -nap | grep :750` and `netstat -nap | grep :88`

Goals
    Enable sshd(8) Kerberos authentication.
    Enable PAM Kerberos authentication.
    SASL GSSAPI OpenLDAP authentication.
    Use SASL GSSAPI Authentication with AutoFS.
IMPORTANT : Kerberos clients require connectivity to the KDC's TCP ports 88 and 749.

renewable tickets is per default disallowed in the most linux distributions. This can be done per:
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN

###

module.exports.push module.exports.configure = (ctx) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  throw new Error "Kerberos property kadmin_principal is required" unless kadmin_principal
  throw new Error "Kerberos property kadmin_password is required" unless kadmin_password
  throw new Error "Kerberos property kadmin_server is required" unless kadmin_server
  throw new Error "Kerberos property realm is required" unless realm
  ctx.config.krb5_client.realm = ctx.config.krb5_client.realm.toUpperCase()
  unless ctx.config.krb5_client.etc_krb5_conf
    REALM = ctx.config.krb5_client.realm
    realm = REALM.toLowerCase()
    etc_krb5_conf =
      'logging':
        'default': 'SYSLOG:INFO:LOCAL1'
        'kdc': 'SYSLOG:NOTICE:LOCAL1'
        'admin_server': 'SYSLOG:WARNING:LOCAL1'
      'libdefaults': 
        'default_realm': REALM
        'dns_lookup_realm': false
        'dns_lookup_kdc': false
        'ticket_lifetime': '24h'
        'renew_lifetime': '7d'
        'forwardable': true
      'realms': {}
      'domain_realm': {}
      'appdefaults':
        'pam':
          'debug': false
          'ticket_lifetime': 36000
          'renew_lifetime': 36000
          'forwardable': true
          'krb4_convert': false
    etc_krb5_conf.realms["#{REALM}"] = 
      'kdc': ctx.config.krb5_client.kdc or realm
      'admin_server': ctx.config.krb5_client.kadmin_server or realm
      'default_domain': ctx.config.krb5_client.default_domain or realm
    etc_krb5_conf.domain_realm[".#{realm}"] = REALM
    etc_krb5_conf.domain_realm["#{realm}"] = REALM
    ctx.config.krb5_client.etc_krb5_conf = etc_krb5_conf
  ctx.config.krb5_client.sshd ?= {}
  ctx.config.krb5_client.sshd = misc.merge
    ChallengeResponseAuthentication: 'yes'
    KerberosAuthentication: 'yes'
    KerberosOrLocalPasswd: 'yes'
    KerberosTicketCleanup: 'yes'
    GSSAPIAuthentication: 'yes'
    GSSAPICleanupCredentials: 'yes'
  , ctx.config.krb5_client.sshd

module.exports.push name: 'Krb5 client # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service [
    name: 'krb5-workstation'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'Krb5 client # Configure', timeout: -1, callback: (ctx, next) ->
  # Kerberos config is also managed by the kerberos server action.
  ctx.log 'Check who manage /etc/krb5.conf'
  return next null, ctx.DISABLED if ctx.actions.some (action) -> action.name is 'phyla/actions/krb5_server'
  # return next null if ctx.hasAction 'phyla/actions/krb5_server'
  {etc_krb5_conf} = ctx.config.krb5_client
  ctx.log 'Update /etc/krb5.conf'
  ctx.ini
    content: etc_krb5_conf
    destination: '/etc/krb5.conf'
    stringify: misc.ini.stringify_square_then_curly
  , (err, written) ->
    return next err, if written then ctx.OK else ctx.PASS

###
Create host principal
---------------------

Note, I have experienced random situations where next was called multiple times.
###
module.exports.push name: 'Krb5 client # Create host principal', timeout: 100000, callback: (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  # quit = false
  ctx.log 'Create an admin user principal and assign a password to this new user'
  ctx.krb5_addprinc
    principal: "host/#{ctx.config.host}@#{realm}"
    randkey: true
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    return next err if err
    modified = true if created
    next null, if modified then ctx.OK else ctx.PASS

module.exports.push name: 'Krb5 client # Configure SSHD', timeout: -1, callback: (ctx, next) ->
  {sshd} = ctx.config.krb5_client
  return next null, ctx.DISABLED unless sshd
  # write = []
  # for k, v of sshd
  #   write.push
  #     match: new RegExp "^#{k}.*$", 'mg'
  #     replace: "#{k} #{v}"
  #     append: true
  write = for k, v of sshd
    match: new RegExp "^#{k}.*$", 'mg'
    replace: "#{k} #{v}"
    append: true
  ctx.log 'Write /etc/ssh/sshd_config'
  ctx.write
    write: write
    destination: '/etc/ssh/sshd_config'
  , (err, written) ->
    return next err if err
    return next null, ctx.PASS unless written
    ctx.log 'Restart openssh'
    ctx.service
      name: 'openssh'
      srv_name: 'sshd'
      action: 'restart'
    , (err, restarted) ->
      next err, ctx.OK

