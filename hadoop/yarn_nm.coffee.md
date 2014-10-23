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

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./yarn').configure ctx
      {host, ryba} = ctx.config
      {yarn_site} = ryba
      yarn_site['yarn.nodemanager.address'] ?= "#{host}:45454"
      yarn_site['yarn.nodemanager.localizer.address'] ?= "#{host}:8040"
      yarn_site['yarn.nodemanager.webapp.address'] ?= "#{host}:8042"
      yarn_site['yarn.nodemanager.webapp.https.address'] ?= "#{host}:8044"
      # See '~/www/src/hadoop/hadoop-common/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/conf/YarnConfiguration.java#263'
      # yarn_site['yarn.nodemanager.webapp.spnego-principal']
      # yarn_site['yarn.nodemanager.webapp.spnego-keytab-file']

## IPTables

| Service    | Port | Proto  | Parameter                          |
|------------|------|--------|------------------------------------|
| nodemanager | 45454 | tcp  | yarn.nodemanager.address           | x
| nodemanager | 8040  | tcp  | yarn.nodemanager.localizer.address |
| nodemanager | 8042  | tcp  | yarn.nodemanager.webapp.address    |
| nodemanager | 8044  | tcp  | yarn.nodemanager.webapp.https.address    |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop YARN NM # IPTables', callback: (ctx, next) ->
      {yarn_site} = ctx.config.ryba
      nm_port = yarn_site['yarn.nodemanager.address'].split(':')[1]
      nm_localizer_port = yarn_site['yarn.nodemanager.localizer.address'].split(':')[1]
      nm_webapp_port = yarn_site['yarn.nodemanager.webapp.address'].split(':')[1]
      nm_webapp_https_port = yarn_site['yarn.nodemanager.webapp.https.address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Container" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_localizer_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Localizer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web Secured UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-yarn-nodemanager".

    module.exports.push name: 'Hadoop YARN NM # Startup', callback: (ctx, next) ->
      {yarn_pid_dir} = ctx.config.ryba
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
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

    module.exports.push name: 'Hadoop YARN NM # Directories', timeout: -1, callback: (ctx, next) ->
      {yarn_user, yarn_site, test_user, hadoop_group} = ctx.config.ryba
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      log_dirs = yarn_site['yarn.nodemanager.log-dirs'].split ','
      local_dirs = yarn_site['yarn.nodemanager.local-dirs'].split ','
      ctx.mkdir [
        destination: log_dirs
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      ,
        destination: local_dirs
        uid: yarn_user.name
        gid: hadoop_group.name
        mode: 0o0755
      ], (err, created) ->
        return next err if err
        cmds = []
        for dir in log_dirs then cmds.push cmd: "su -l #{test_user.name} -c 'ls -l #{dir}'"
        for dir in local_dirs then cmds.push cmd: "su -l #{test_user.name} -c 'ls -l #{dir}'"
        ctx.execute cmds, (err) ->
          next err, created

    module.exports.push name: 'Hadoop YARN NM # Configure', callback: (ctx, next) ->
      {yarn_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn_site
        merge: true
      , next

    module.exports.push name: 'Hadoop YARN NM # Kerberos', callback: (ctx, next) ->
      {yarn_user, realm} = ctx.config.ryba
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
      , next

    module.exports.push 'ryba/hadoop/yarn_nm_start'


