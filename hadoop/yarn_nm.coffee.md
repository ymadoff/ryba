---
title: 
layout: module
---

# YARN NodeManager

ResourceManager is the central authority that manages resources and schedules
applications running atop of YARN.

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/yarn'

    module.exports.push (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./yarn').configure ctx

## IPTables

| Service    | Port | Proto  | Parameter                          |
|------------|------|--------|------------------------------------|
| nodemanager | 45454 | tcp  | yarn.nodemanager.address           | x
| nodemanager | 8042  | tcp  | yarn.nodemanager.webapp.address    |
| nodemanager | 8040  | tcp  | yarn.nodemanager.localizer.address |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP YARN NM # IPTables', callback: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 45454, protocol: 'tcp', state: 'NEW', comment: "YARN NM Container" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8042, protocol: 'tcp', state: 'NEW', comment: "YARN NM WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8040, protocol: 'tcp', state: 'NEW', comment: "YARN NM WebApp" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-yarn-nodemanager".

    module.exports.push name: 'HDP YARN NM # Startup', callback: (ctx, next) ->
      {yarn_pid_dir} = ctx.config.hdp
      modified = false
      do_install = ->
        ctx.service
          name: 'hadoop-yarn-nodemanager'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write
          destination: '/etc/init.d/hadoop-yarn-nodemanager'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{yarn_pid_dir}/$SVC_USER/yarn-yarn-nodemanager.pid\""
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_install()

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
      resourcemanager = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      ctx.waitIsOpen resourcemanager, 8088, (err) ->
        return next err if err
        lifecycle.nm_start ctx, (err, started) ->
          next err, if started then ctx.OK else ctx.PASS

