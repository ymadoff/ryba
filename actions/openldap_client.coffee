
###
OpenLDAP Client
===============

Install and configure the OpenLDAP client utilities. The
file "/etc/openldap/ldap.conf" is configured by the "openldap_client.config"
object property. The property "openldap_client.ca_cert" define the 
certificate upload if not null.

SSL certifcate could be defined in "/etc/ldap.conf" by 
the "TLS_CACERT" or the "TLS_CACERTDIR" properties. When 
using "TLS_CACERTDIR", the name of the file  must be the 
certicate hash with a numeric suffix. Here's an example 
showing how to place the certificate inside "TLS_CACERTDIR":

    hash=`openssl x509 -noout -hash -in cert.pem`
    mv cert.pem /etc/openldap/cacerts/$hash.0

###
{merge} = require 'mecano/lib/misc'
module.exports = []

module.exports.push 'histi/actions/yum'

module.exports.push (ctx) ->
  ctx.config.openldap_client ?= {}
  ctx.config.openldap_client.config ?= {}
  ctx.config.openldap_client.ca_cert ?= null

module.exports.push (ctx, next) ->
  @name 'OpenLDAP Client # Install'
  @timeout -1
  ctx.service
    name: 'openldap-clients'
  , (err, installed) ->
    next err, if installed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'OpenLDAP Client # Configure'
  {config} = ctx.config.openldap_client
  write = []
  for k, v of config
    write.push
      match: new RegExp "^#{k}.*$", 'mg'
      replace: "#{k} #{v}"
      append: true
  ctx.write
    write: write
    destination: '/etc/openldap/ldap.conf'
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'OpenLDAP Client # Upload certificate'
  {ca_cert} = ctx.config.openldap_client
  return next null, ctx.DISABLED unless ca_cert
  ctx.upload ca_cert, (err, uploaded) ->
    next err, if uploaded then ctx.OK else ctx.PASS



