---
title: 
layout: module
---

# Zookeeper Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    # module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/lib/base'
    module.exports.push require('./server').configure

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

    module.exports.push name: 'ZooKeeper Server # Users & Groups', callback: (ctx, next) ->
      {zookeeper_group, hadoop_group, zookeeper_user} = ctx.config.ryba
      ctx.group [zookeeper_group, hadoop_group], (err, gmodified) ->
        return next err if err
        ctx.user zookeeper_user, (err, umodified) ->
          next err, gmodified or umodified

## IPTables

| Service    | Port | Proto  | Parameter          |
|------------|------|--------|--------------------|
| zookeeper  | 2181 | tcp    | hdp.zookeeper_port |
| zookeeper  | 2888 | tcp    | -                  |
| zookeeper  | 3888 | tcp    | -                  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'ZooKeeper Server # IPTables', callback: (ctx, next) ->
      {zookeeper_port} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: zookeeper_port, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Client" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 2888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Peer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Leader" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Install

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

    module.exports.push name: 'ZooKeeper Server # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        {name: 'zookeeper'}
        {name: 'telnet'} # Used by check
      ], next

## Startup

Install and configure the startup script in 
"/etc/init.d/zookeeper-server".

    module.exports.push name: 'ZooKeeper Server # Startup', callback: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service
          name: 'zookeeper-server'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write
          destination: '/etc/init.d/zookeeper-server'
          match: /^(\. .*\/bigtop-detect-javahome)$/m
          replace: "#$1"
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

## Kerberos

    module.exports.push name: 'ZooKeeper Server # Kerberos', timeout: -1, callback: (ctx, next) ->
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
          do_server_jaas()
      do_server_jaas = ->
        ctx.write
          destination: '/etc/zookeeper/conf/zookeeper-server.jaas'
          content: """
          Server {
            com.sun.security.auth.module.Krb5LoginModule required
            useKeyTab=true
            storeKey=true
            useTicketCache=false
            keyTab="#{zookeeper_conf_dir}/zookeeper.keytab"
            principal="zookeeper/#{ctx.config.host}@#{realm}";
          };
          """
        , (err, written) ->
          next err if err
          modified = true if written
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

## Layout

Create the data, pid and log directories with the correct permissions and
ownerships.

    module.exports.push name: 'ZooKeeper Server # Layout', callback: (ctx, next) ->
      { hadoop_group, zookeeper_user, 
        zookeeper_conf, zookeeper_pid_dir, zookeeper_log_dir
      } = ctx.config.ryba
      ctx.mkdir [
        destination: zookeeper_conf['dataDir']
        uid: zookeeper_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: zookeeper_pid_dir
        uid: zookeeper_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: zookeeper_log_dir
        uid: zookeeper_user.name
        gid: hadoop_group.name
        mode: 0o755
      ], next

    module.exports.push name: 'ZooKeeper Server # Environment', callback: (ctx, next) ->
      {zookeeper_conf_dir, zookeeper_env} = ctx.config.ryba
      write = for k, v of zookeeper_env
        match: RegExp "^export\\s+(#{quote k})=(.*)$", 'mg'
        replace: "export #{k}=#{v}"
        append: true
      ctx.write
        destination: "#{zookeeper_conf_dir}/zookeeper-env.sh"
        write: write
        backup: true
        eof: true
      , next

    module.exports.push name: 'ZooKeeper Server # Configure', callback: (ctx, next) ->
      modified = false
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      {zookeeper_conf_dir, zookeeper_conf} = ctx.config.ryba
      write = for k, v of zookeeper_conf
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
        append: true
      ctx.write
        destination: "#{zookeeper_conf_dir}/zoo.cfg"
        write: write
        backup: true
        eof: true
      , next

## Super User

Enables a ZooKeeper ensemble administrator to access the znode hierarchy as a
"super" user.

This functionnality is disactivated by default. Enable it by setting the
configuration property "ryba.zookeeper_superuser_password". The digest auth
passes the authdata in plaintext to the server. Use this authentication method
only on localhost (not over the network) or over an encrypted connection.

Run "zkCli.sh" and enter `addauth digest super:EjV93vqJeB3wHqrx` 

    module.exports.push name: 'ZooKeeper Server # Super User', callback: (ctx, next) ->
      {zookeeper_conf_dir, zookeeper_superuser_password} = ctx.config.ryba
      return next() unless zookeeper_superuser_password
      ctx.execute
        cmd: """
        export ZK_HOME=/usr/lib/zookeeper/
        java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:#{zookeeper_superuser_password}
        """
      , (err, _, stdout) ->
        digest = match[1] if match = /\->(.*)/.exec(stdout)
        return next Error "Failed to get digest" unless digest
        ctx.write
          destination: "#{zookeeper_conf_dir}/zookeeper-env.sh"
          # match: RegExp "^export CLIENT_JVMFLAGS=\"-D#{quote 'zookeeper.DigestAuthenticationProvider.superDigest'}=.* #{quote '${CLIENT_JVMFLAGS}'}$", 'mg'
          # replace: "export CLIENT_JVMFLAGS=\"-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} ${CLIENT_JVMFLAGS}\""
          match: RegExp "^export SERVER_JVMFLAGS=\"-D#{quote 'zookeeper.DigestAuthenticationProvider.superDigest'}=.* #{quote '${SERVER_JVMFLAGS}'}$", 'mg'
          replace: "export SERVER_JVMFLAGS=\"-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} ${SERVER_JVMFLAGS}\""
          append: true
          backup: true
          eof: true
        , next

    module.exports.push name: 'ZooKeeper Server # Write myid', callback: (ctx, next) ->
      {hadoop_group, zookeeper_user, zookeeper_myid, zookeeper_conf} = ctx.config.ryba
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      return next() if hosts.length is 1
      unless zookeeper_myid
        for host, i in hosts
          zookeeper_myid = i+1 if host is ctx.config.host
      ctx.write
        content: zookeeper_myid
        destination: "#{zookeeper_conf['dataDir']}/myid"
        uid: zookeeper_user.name
        gid: hadoop_group.name
      , next

    module.exports.push 'ryba/zookeeper/server_start'

    module.exports.push 'ryba/zookeeper/server_check'

## Resources

*   [ZooKeeper Resilience](http://blog.cloudera.com/blog/2014/03/zookeeper-resilience-at-pinterest/)

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-zookeeper-1.html

## Module Dependencies

    quote = require 'regexp-quote'



