---
title: 
layout: module
---

# YARN NodeManager

ResourceManager is the central authority that manages resources and schedules
applications running atop of YARN.

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'riba/hadoop/yarn'

    module.exports.push (ctx) ->
      require('./yarn').configure ctx

    module.exports.push name: 'HDP YARN NM # Directories', timeout: -1, callback: (ctx, next) ->
      {yarn_user, yarn, test_user, hadoop_group} = ctx.config.hdp
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      ctx.mkdir [
        destination: yarn['yarn.nodemanager.log-dirs']
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      ,
        destination: yarn['yarn.nodemanager.local-dirs']
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      ], (err, created) ->
        return next err if err
        cmds = []
        for dir in yarn['yarn.nodemanager.log-dirs'] then cmds.push cmd: "su -l #{test_user.name} -c 'ls -l #{dir}'"
        for dir in yarn['yarn.nodemanager.local-dirs'] then cmds.push cmd: "su -l #{test_user.name} -c 'ls -l #{dir}'"
        ctx.execute cmds, (err) ->
          next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN NM # Kerberos', callback: (ctx, next) ->
      {yarn_user, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "nm/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nm.service.keytab"
        uid: yarn_user.name
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP YARN NM # Start', timeout: -1, callback: (ctx, next) ->
      resourcemanager = ctx.host_with_module 'riba/hadoop/yarn_rm'
      ctx.waitIsOpen resourcemanager, 8088, (err) ->
        return next err if err
        lifecycle.nm_start ctx, (err, started) ->
          next err, if started then ctx.OK else ctx.PASS

