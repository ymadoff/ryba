---
title: 
layout: module
---

# Zookeeper

    lifecycle = require '../lib/lifecycle'
    quote = require 'regexp-quote'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/krb5_client'

## Configure

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('masson/core/krb5_client').configure ctx
      {java_home} = ctx.config.java
      # User
      ctx.config.ryba.zookeeper_user = name: ctx.config.ryba.zookeeper_user if typeof ctx.config.ryba.zookeeper_user is 'string'
      ctx.config.ryba.zookeeper_user ?= {}
      ctx.config.ryba.zookeeper_user.name ?= 'zookeeper'
      ctx.config.ryba.zookeeper_user.system ?= true
      ctx.config.ryba.zookeeper_user.gid ?= 'zookeeper'
      ctx.config.ryba.zookeeper_user.groups ?= 'hadoop'
      ctx.config.ryba.zookeeper_user.comment ?= 'Zookeeper User'
      ctx.config.ryba.zookeeper_user.home ?= '/var/lib/zookeeper'
      # Groups
      ctx.config.ryba.zookeeper_group = name: ctx.config.ryba.zookeeper_group if typeof ctx.config.ryba.zookeeper_group is 'string'
      ctx.config.ryba.zookeeper_group ?= {}
      ctx.config.ryba.zookeeper_group.name ?= 'zookeeper'
      ctx.config.ryba.zookeeper_group.system ?= true
      # Hadoop Group is also defined in ryba/hadoop/core
      ctx.config.ryba.hadoop_group = name: ctx.config.ryba.hadoop_group if typeof ctx.config.ryba.hadoop_group is 'string'
      ctx.config.ryba.hadoop_group ?= {}
      ctx.config.ryba.hadoop_group.name ?= 'hadoop'
      ctx.config.ryba.hadoop_group.system ?= true
      # Layout
      ctx.config.ryba.zookeeper_data_dir ?= '/var/zookeper/data/'
      ctx.config.ryba.zookeeper_conf_dir ?= '/etc/zookeeper/conf'
      ctx.config.ryba.zookeeper_log_dir ?= '/var/log/zookeeper'
      ctx.config.ryba.zookeeper_pid_dir ?= '/var/run/zookeeper'
      ctx.config.ryba.zookeeper_port ?= 2181
      # Layout
      ctx.config.ryba.zookeeper_conf_dir ?= '/etc/zookeeper/conf'
      # Environnment
      ctx.config.ryba.zookeeper_env ?= {}
      ctx.config.ryba.zookeeper_env['JAVA_HOME'] ?= "#{java_home}"
      ctx.config.ryba.zookeeper_env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'

    module.exports.push name: 'ZooKeeper Client # Kerberos', timeout: -1, callback: (ctx, next) ->
      {zookeeper_user, hadoop_group, realm, zookeeper_conf_dir} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      do_principal = ->
        ctx.krb5_addprinc
          principal: "zookeeper/#{ctx.config.host}@#{realm}"
          randkey: true
          keytab: "#{zookeeper_conf_dir}/zookeeper.keytab"
          uid: zookeeper_user.name
          gid: hadoop_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_client_jaas()
      do_client_jaas = ->
        ctx.write
          destination: "#{zookeeper_conf_dir}/zookeeper-client.jaas"
          content: """
          Client {
            com.sun.security.auth.module.Krb5LoginModule required
            useKeyTab=false
            useTicketCache=true;
          };
          """
        , (err, written) ->
          next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_principal()

    module.exports.push name: 'ZooKeeper Client # Environment', callback: (ctx, next) ->
      {zookeeper_conf_dir, zookeeper_env} = ctx.config.ryba
      write = for k, v of zookeeper_env
        match: RegExp "^export\\s+(#{quote k})=(.*)$", 'mg'
        replace: "export #{k}=#{v}"
        append: true
      ctx.write
        destination: "#{zookeeper_conf_dir}/zookeeper-env.sh"
        write: write
        backup: true
      , next



