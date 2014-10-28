---
title: 
layout: module
---

# Zookeeper Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push require('./client').configure

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

## Module Dependencies

    quote = require 'regexp-quote'





