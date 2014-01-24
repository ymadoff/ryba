
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
url = require 'url'
each = require 'each'
{merge} = require 'mecano/lib/misc'
module.exports = []

module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/nc'

module.exports.push (ctx) ->
  require('./nc').configure ctx
  ctx.config.openldap_client ?= {}
  ctx.config.openldap_client.config ?= {}
  ctx.config.openldap_client.ca_cert ?= null

module.exports.push name: 'OpenLDAP Client # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service
    name: 'openldap-clients'
  , (err, installed) ->
    next err, if installed then ctx.OK else ctx.PASS

module.exports.push name: 'OpenLDAP Client # Configure', timeout: -1, callback: (ctx, next) ->
  {config} = ctx.config.openldap_client
  write = []
  for k, v of config
    v = v.join(' ') if k.toLowerCase() is 'uri'
    write.push
      match: new RegExp "^#{k}.*$", 'mg'
      replace: "#{k} #{v}"
      append: true
  ctx.write
    write: write
    destination: '/etc/openldap/ldap.conf'
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS

module.exports.push name: 'OpenLDAP Client # Upload certificate', timeout: -1, callback: (ctx, next) ->
  {ca_cert} = ctx.config.openldap_client
  return next null, ctx.DISABLED unless ca_cert
  ctx.upload ca_cert, (err, uploaded) ->
    next err, if uploaded then ctx.OK else ctx.PASS

module.exports.push name: 'OpenLDAP Client # Check URI', timeout: -1, callback: (ctx, next) ->
  {config} = ctx.config.openldap_client
  uris = []
  for k, v of config
    continue unless k.toLowerCase() is 'uri'
    for uri in v then uris.push uri
  each(uris)
  .on 'item', (uri, next) ->
    uri = url.parse uri
    return next() if ['ldap:', 'ldaps:'].indexOf(uri.protocol) is -1
    uri.port ?= 389 if uri.protocol is 'ldap:'
    uri.port ?= 636 if uri.protocol is 'ldaps:'
    ctx.waitForConnection uri.hostname, uri.port, next
  .on 'both', (err) ->
    next err, ctx.PASS



