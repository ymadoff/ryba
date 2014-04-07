---
title: 
layout: module
---

# YARN NodeManager

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'phyla/hadoop/yarn'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP YARN NM # Kerberos', callback: (ctx, next) ->
      {yarn_user, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "nm/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nm.service.keytab"
        uid: yarn_user
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN NM # Start', timeout: -1, callback: (ctx, next) ->
      resourcemanager = ctx.host_with_module 'phyla/hadoop/yarn_rm'
      ctx.waitIsOpen resourcemanager, 8088, (err) ->
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
