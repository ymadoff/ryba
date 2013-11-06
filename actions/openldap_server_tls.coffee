
###
OpenLDAP TLS
============

try:
openldap-devel
http://www.computerglitch.net/blog/blog/2013/04/04/centos-6-dot-3-ldap-with-tls-quick-and-dirty/

For the client, add self-signed certificates inside "TLS_CACERT" defined in "/etc/openldap/ldap.conf".

Whether the SSL connection works can be tested with: 
    openssl s_client -connect 10.10.10.11:636
To test whether the SSL connection is working correctly with LDAP, use the following command: 
    ldapsearch -x -H ldaps://openldap.domain.com -b <BASEDN> -D <binddn> -w
    eg: ldapsearch -x -H ldaps://openldap.hadoop -D cn=Manager,dc=adaltas,dc=com -w test -b "dc=adaltas,dc=com"


From "http://itdavid.blogspot.ca/2012/05/howto-centos-6.html":

    mkdir key && cd key
    # User read and write permissions only
    umask 066
    # Private RSA key
    openssl genrsa -out privkey.pem 2048
    # Certificate Signing Request file
    openssl req -new -key privkey.pem -out server.csr
    # Self-sign the certificate
    openssl x509 -req -days 1095 -in server.csr -signkey privkey.pem -out server.pem
    # Fix permissions and ownership
    chmod 400 privkey.pem
    chown ldap:ldap privkey.pem
    chmod 400 server.pem
    chown ldap:ldap server.pem
    # Rename the certificate for the openldap client
    # cp -rp server.pem `openssl x509 -noout -in server.pem -hash`
    # Place the files in their respective locations
    mv privkey.pem /etc/pki/tls/certs/adaltas-key.pem
    mv server.pem /etc/pki/tls/certs/adaltas-cert.pem
    # ldapmodify -D cn=admin,cn=config -w test <<-EOF
    # dn: cn=config
    # add: olcTLSCertificateFile
    # olcTLSCertificateFile: /etc/pki/tls/certs/adaltas.com.pem
    # -
    # add: olcTLSCertificateKeyFile
    # olcTLSCertificateKeyFile: /etc/pki/tls/certs/adaltas.com.key
    # EOF
    echo olcTLSCertificateFile: /etc/pki/tls/certs/adaltas-cert.pem >> /etc/openldap/slapd.d/cn=config.ldif
    echo olcTLSCertificateKeyFile: /etc/pki/tls/certs/adaltas-privkey.pem >> /etc/openldap/slapd.d/cn=config.ldif

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/certs/test02.key -out /etc/pki/tls/certs/test02.crt
    olcTLSCertificateFile: /etc/pki/tls/certs/test02.crt
    olcTLSCertificateKeyFile: /etc/pki/tls/certs/test02.key

    service slapd restart
    ldapsearch -x -ZZ -d3 -H ldaps://duzy01.adaltas.com -D cn=Manager,dc=adaltas,dc=com -w DuzY123  -b "dc=adaltas,dc=com"
    ldapsearch -x -ZZ -d3 -H ldaps://openldap.hadoop -D cn=Manager,dc=adaltas,dc=com -w test  -b "dc=adaltas,dc=com"

View certificate information

    openssl x509 -in /etc/pki/tls/certs/adaltas-cert.pem -text -noout
    openssl x509 -in /etc/pki/tls/certs/test02.crt -text -noout

    openssl verify -CAfile /etc/pki/tls/certs/test02.crt /etc/pki/tls/certs/test02.key
    openssl verify -CAfile /etc/pki/tls/certs/adaltas-cert.pem /etc/pki/tls/certs/adaltas-key.pem 

###
path = require 'path'
module.exports = []

module.exports.push 'histi/actions/openldap_server'
module.exports.push 'histi/actions/openldap_client'

module.exports.push (ctx) ->
  ctx.config.openldap_server ?= {}
  ctx.config.openldap_server.tls_cert_file ?= null
  ctx.config.openldap_server.tls_key_file ?= null

module.exports.push (ctx, next) ->
  @name 'OpenLDAP TLS # Deploy'
  @timeout -1
  { tls, tls_cert_file, tls_key_file } = ctx.config.openldap_server
  tls_cert_filename = path.basename tls_cert_file
  tls_key_filename = path.basename tls_key_file
  console.log tls_cert_file
  console.log tls_key_file
  return next null, ctx.DISABLED unless tls
  modified = false
  ctx.log 'Write certificate files'
  ctx.write [
    source: tls_cert_file
    local_source: true
    destination: "/etc/pki/tls/certs/#{tls_cert_filename}"
    uid: 'ldap'
    gid: 'ldap'
    mode: '400'
  ,
    source: tls_key_file
    local_source: true
    destination: "/etc/pki/tls/certs/#{tls_key_filename}"
    uid: 'ldap'
    gid: 'ldap'
    mode: '400'
  ,
    destination: '/etc/openldap/slapd.d/cn=config.ldif'
    write: [
      match: /^olcTLSCertificateFile.*$/mg
      replace: "olcTLSCertificateFile: /etc/pki/tls/certs/#{tls_cert_filename}"
      append: 'olcRootPW'
    ,
      match: /^olcTLSCertificateKeyFile.*$/mg
      replace: "olcTLSCertificateKeyFile: /etc/pki/tls/certs/#{tls_key_filename}"
      append: 'olcTLSCertificateFile'
    ]
  ], (err, written) ->
    # edit /etc/sysconfig/ldap
    return next err if err
    modified = true if written
    ctx.log 'Listen ldaps interface'
    ctx.write
      match: /^SLAPD_LDAPS.*/mg
      replace: 'SLAPD_LDAPS=yes'
      destination: '/etc/sysconfig/ldap'
    , (err, written) ->
      return next err if err
      modified = true if written
      return next null, ctx.PASS unless modified
      ctx.log 'Restart service'
      ctx.service
        name: 'openldap-servers'
        srv_name: 'slapd'
        action: 'restart'
      , (err, restarted) ->
        return next err if err
        ctx.log 'Check secure connection'
        next null, ctx.OK

module.exports.push (ctx, next) ->
  @name 'OpenLDAP TLS # Check'
  { suffix, root_dn, root_password } = ctx.config.openldap_server
  ctx.execute
    cmd: "ldapsearch -x -H ldaps://#{ctx.config.host} -b #{suffix} -D #{root_dn} -w #{root_password}"
  , (err, executed) ->
    next err, ctx.PASS













