
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push 'phyla/hdp/hdfs'

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP HDFS SNN # Kerberos', callback: (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc 
    principal: "nn/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/nn.service.keytab"
    uid: 'hdfs'
    gid: 'hadoop'
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS SNN # Start', callback: (ctx, next) ->
  lifecycle.snn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS