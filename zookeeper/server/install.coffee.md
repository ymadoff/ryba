
# Zookeeper Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    # module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/lib/base'
    module.exports.push require '../../lib/hdp_service'
    module.exports.push require '../../lib/write_jaas'
    module.exports.push require('./index').configure

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

    module.exports.push name: 'ZooKeeper Server # Users & Groups', handler: (ctx, next) ->
      {zookeeper, hadoop_group} = ctx.config.ryba
      ctx.group [zookeeper.group, hadoop_group], (err, gmodified) ->
        return next err if err
        ctx.user zookeeper.user, (err, umodified) ->
          next err, gmodified or umodified

## IPTables

| Service    | Port | Proto  | Parameter          |
|------------|------|--------|--------------------|
| zookeeper  | 2181 | tcp    | hdp.zookeeper_port |
| zookeeper  | 2888 | tcp    | -                  |
| zookeeper  | 3888 | tcp    | -                  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'ZooKeeper Server # IPTables', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: zookeeper.port, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Client" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 2888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Peer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Leader" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Install

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

    module.exports.push name: 'ZooKeeper Server # Install', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'telnet' # Used by check
      , (err) ->
        return next err if err
        ctx.hdp_service
          name: 'zookeeper-server'
        , next

## Kerberos

    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push name: 'ZooKeeper Server # Kerberos', timeout: -1, handler: (ctx, next) ->
      {zookeeper, hadoop_group, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      do_principal = ->
        ctx.krb5_addprinc
          principal: "zookeeper/#{ctx.config.host}@#{realm}"
          randkey: true
          keytab: "#{zookeeper.conf_dir}/zookeeper.keytab"
          uid: zookeeper.user.name
          gid: hadoop_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_server_jaas()
      do_server_jaas = ->
        ctx.write_jaas
          destination: '/etc/zookeeper/conf/zookeeper-server.jaas'
          content: Server:
            principal: "zookeeper/#{ctx.config.host}@#{realm}"
            keyTab: "#{zookeeper.conf_dir}/zookeeper.keytab"
          uid: zookeeper.user.name
          gid: hadoop_group.name
        , (err, written) ->
          next err if err
          modified = true if written
          do_client_jaas()
      do_client_jaas = ->
        ctx.write_jaas
          destination: "#{zookeeper.conf_dir}/zookeeper-client.jaas"
          content: Client:
            useTicketCache: true
          mode: 0o0644
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

    module.exports.push name: 'ZooKeeper Server # Layout', handler: (ctx, next) ->
      {zookeeper, hadoop_group} = ctx.config.ryba
      ctx.mkdir [
        destination: zookeeper.config['dataDir']
        uid: zookeeper.user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: zookeeper.pid_dir
        uid: zookeeper.user.name
        gid: zookeeper.group.name
        mode: 0o755
      ,
        destination: zookeeper.log_dir
        uid: zookeeper.user.name
        gid: hadoop_group.name
        mode: 0o755
      ], next

## Environment

    module.exports.push name: 'ZooKeeper Server # Environment', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      write = for k, v of zookeeper.env
        match: RegExp "^export\\s+(#{quote k})=(.*)$", 'm'
        replace: "export #{k}=\"#{v}\""
        append: true
      ctx.write
        destination: "#{zookeeper.conf_dir}/zookeeper-env.sh"
        write: write
        backup: true
        eof: true
      , next

## Configure

Update the file "zoo.cfg" with the properties defined by the
"ryba.zookeeper.config" configuration.

    module.exports.push name: 'ZooKeeper Server # Configure', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      write = for k, v of zookeeper.config
        match: RegExp "^#{quote k}=.*$", 'mg'
        replace: "#{k}=#{v}"
        append: true
      ctx.write
        destination: "#{zookeeper.conf_dir}/zoo.cfg"
        write: write
        backup: true
        eof: true
      , next

## Log4J

Upload the ZooKeeper loging configuration file.

    module.exports.push name: 'ZooKeeper Server # Log4J', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      ctx.upload
        destination: "#{zookeeper.conf_dir}/log4j.properties"
        source: "#{__dirname}/../../resources/zookeeper/log4j.properties"
      , next



## Super User

Enables a ZooKeeper ensemble administrator to access the znode hierarchy as a
"super" user.

This functionnality is disactivated by default. Enable it by setting the
configuration property "ryba.zookeeper.superuser.password". The digest auth
passes the authdata in plaintext to the server. Use this authentication method
only on localhost (not over the network) or over an encrypted connection.

Run "zkCli.sh" and enter `addauth digest super:EjV93vqJeB3wHqrx`

    module.exports.push name: 'ZooKeeper Server # Super User', handler: (ctx, next) ->
      {zookeeper} = ctx.config.ryba
      return next() unless zookeeper.superuser.password
      ctx.execute
        cmd: """
        ZK_HOME=/usr/hdp/current/zookeeper-client/
        java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:#{zookeeper.superuser.password}
        """
      , (err, _, stdout) ->
        digest = match[1] if match = /\->(.*)/.exec(stdout)
        return next Error "Failed to get digest" unless digest
        ctx.write
          destination: "#{zookeeper.conf_dir}/zookeeper-env.sh"
          # match: RegExp "^export CLIENT_JVMFLAGS=\"-D#{quote 'zookeeper.DigestAuthenticationProvider.superDigest'}=.* #{quote '${CLIENT_JVMFLAGS}'}$", 'mg'
          # replace: "export CLIENT_JVMFLAGS=\"-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} ${CLIENT_JVMFLAGS}\""
          match: /^export SERVER_JVMFLAGS="-Dzookeeper\.DigestAuthenticationProvider\.superDigest=.* \${SERVER_JVMFLAGS}"$/m
          replace: "export SERVER_JVMFLAGS=\"-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} ${SERVER_JVMFLAGS}\""
          append: true
          backup: true
          eof: true
        , next

    module.exports.push name: 'ZooKeeper Server # Write myid', handler: (ctx, next) ->
      {zookeeper, hadoop_group} = ctx.config.ryba
      hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      return next() if hosts.length is 1
      unless zookeeper.myid
        for host, i in hosts
          zookeeper.myid = i+1 if host is ctx.config.host
      ctx.write
        content: zookeeper.myid
        destination: "#{zookeeper.config['dataDir']}/myid"
        uid: zookeeper.user.name
        gid: hadoop_group.name
      , next

## Resources

*   [ZooKeeper Resilience](http://blog.cloudera.com/blog/2014/03/zookeeper-resilience-at-pinterest/)

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-zookeeper-1.html

## Module Dependencies

    quote = require 'regexp-quote'
