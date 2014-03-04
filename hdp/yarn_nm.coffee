
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push 'phyla/core/nc'
module.exports.push 'phyla/hdp/yarn'

module.exports.push (ctx) ->
  require('../core/nc').configure ctx
  require('./yarn').configure ctx

module.exports.push name: 'HDP YARN NM # Kerberos', callback: (ctx, next) ->
  {yarn_user} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc 
    principal: "nm/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/nm.service.keytab"
    uid: yarn_user
    gid: 'hadoop'
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    return next err if err
    next null, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP YARN NM # Start', timeout: -1, callback: (ctx, next) ->
  resourcemanager = ctx.host_with_module 'phyla/hdp/yarn_rm'
  ctx.waitForConnection resourcemanager, 8088, (err) ->
    return next err if err
    lifecycle.nm_start ctx, (err, started) ->
      next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP YARN NM # Test User', callback: (ctx, next) ->
  {test_user, hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd #{test_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop to test\""
    code: 0
    code_skipped: 9
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS