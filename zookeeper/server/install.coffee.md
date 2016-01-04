
# Zookeeper Server Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/lib/base'
    module.exports.push 'ryba/lib/hdp_select'
    module.exports.push 'ryba/lib/write_jaas'
    # module.exports.push require('./index').configure

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

    module.exports.push header: 'ZooKeeper Server # Users & Groups', handler: ->
      {zookeeper, hadoop_group} = @config.ryba
      @group zookeeper.group
      @group hadoop_group
      @user zookeeper.user

## IPTables

| Service    | Port | Proto  | Parameter          |
|------------|------|--------|--------------------|
| zookeeper  | 2181 | tcp    | hdp.zookeeper_port |
| zookeeper  | 2888 | tcp    | -                  |
| zookeeper  | 3888 | tcp    | -                  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'ZooKeeper Server # IPTables', handler: ->
      {zookeeper} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: zookeeper.port, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Client" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 2888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Peer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Leader" }
        ]
        if: @config.iptables.action is 'start'

## Install

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

    module.exports.push header: 'ZooKeeper Server # Install', timeout: -1, handler: ->
      @service
        name: 'telnet' # Used by check
      @service
        name: 'zookeeper-server'
      @hdp_select
        name: 'zookeeper-server'
      @hdp_select
        name: 'zookeeper-client'
      @upload
        source: "#{__dirname}/resources/zookeeper"
        destination: '/etc/init.d/zookeeper-server'
        mode: 0o0755
        unlink: true

## Kerberos

    module.exports.push 'masson/core/krb5_client/wait'

    module.exports.push header: 'ZooKeeper Server # Kerberos', timeout: -1, handler: ->
      {zookeeper, hadoop_group, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: "zookeeper/#{@config.host}@#{realm}"
        randkey: true
        keytab: '/etc/security/keytabs/zookeeper.service.keytab'
        uid: zookeeper.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      @write_jaas
        destination: '/etc/zookeeper/conf/zookeeper-server.jaas'
        content: Server:
          principal: "zookeeper/#{@config.host}@#{realm}"
          keyTab: '/etc/security/keytabs/zookeeper.service.keytab'
        uid: zookeeper.user.name
        gid: hadoop_group.name
      @write_jaas
        destination: "#{zookeeper.conf_dir}/zookeeper-client.jaas"
        content: Client:
          useTicketCache: true
        mode: 0o0644

## Layout

Create the data, pid and log directories with the correct permissions and
ownerships.

    module.exports.push header: 'ZooKeeper Server # Layout', handler: ->
      {zookeeper, hadoop_group} = @config.ryba
      @mkdir
        destination: zookeeper.config['dataDir']
        uid: zookeeper.user.name
        gid: hadoop_group.name
        mode: 0o755
      @mkdir
        destination: zookeeper.pid_dir
        uid: zookeeper.user.name
        gid: zookeeper.group.name
        mode: 0o755
      @mkdir
        destination: zookeeper.log_dir
        uid: zookeeper.user.name
        gid: hadoop_group.name
        mode: 0o755

## Super User

Enables a ZooKeeper ensemble administrator to access the znode hierarchy as a
"super" user.

This functionnality is disactivated by default. Enable it by setting the
configuration property "ryba.zookeeper.superuser.password". The digest auth
passes the authdata in plaintext to the server. Use this authentication method
only on localhost (not over the network) or over an encrypted connection.

Run "zkCli.sh" and enter `addauth digest super:EjV93vqJeB3wHqrx`

    module.exports.push
      header: 'ZooKeeper Server # Generate Super User'
      if: -> @config.ryba.zookeeper.superuser.password
      handler: (_, callback) ->
        {zookeeper} = @config.ryba
        @execute
          cmd: """
          ZK_HOME=/usr/hdp/current/zookeeper-client/
          java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:#{zookeeper.superuser.password}
          """
        , (err, _, stdout) ->
          digest = match[1] if match = /\->(.*)/.exec(stdout)
          return callback Error "Failed to get digest" unless digest
          zookeeper.env['SERVER_JVMFLAGS'] = "-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} #{zookeeper.env['SERVER_JVMFLAGS']}"
          callback()

## Auth to local

    module.exports.push
      header: 'ZooKeeper Server # Auth to local'
      unless: -> @config.ryba.zookeeper.env['SERVER_JVMFLAGS'].indexOf('-Dzookeeper.security.auth_to_local') > -1
      handler: (_, callback) ->
        {zookeeper} = @config.ryba
        auth_to_local = zookeeper.auth_to_local.trim()
        auth_to_local = auth_to_local.replace /[\n\r]/g, '' # remove carriage return
        auth_to_local = auth_to_local.replace /\$/g, '\\$' # properly escape bash special char
        zookeeper.env['SERVER_JVMFLAGS'] += " -Dzookeeper.security.auth_to_local=#{auth_to_local}"
        callback()

## Environment

    module.exports.push header: 'ZooKeeper Server # Environment', handler: ->
      {zookeeper} = @config.ryba
      @write
        destination: "#{zookeeper.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of zookeeper.env).join '\n'
        backup: true
        eof: true

## Configure

Update the file "zoo.cfg" with the properties defined by the
"ryba.zookeeper.config" configuration.

    module.exports.push header: 'ZooKeeper Server # Configure', handler: ->
      {zookeeper} = @config.ryba
      @write
        destination: "#{zookeeper.conf_dir}/zoo.cfg"
        write: for k, v of zookeeper.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Log4J

Upload the ZooKeeper loging configuration file.

    module.exports.push header: 'ZooKeeper Server # Log4J', handler: ->
      {zookeeper} = @config.ryba
      writes = [
        match: /log4j\.rootLogger=.*/g
        replace: "log4j.rootLogger=#{zookeeper.env['ZOO_LOG4J_PROP']}"
      ]
      # Append the configuration of the SocketHubAppender
      if zookeeper.log4j.server_port
        writes.push
          match: /^# Add SOCKET to rootLogger to serve logs to the remote Logstash TCP Client(.*)/m
          replace: "\n#\n# Add SOCKET to rootLogger to serve logs to the remote Logstash TCP Client\n#"
          append: true
        ,
          match: /^log4j.appender.SOCKETHUB=(.*)/m
          replace: "log4j.appender.SOCKETHUB=org.apache.log4j.net.SocketHubAppender"
          append: true
        ,
          match: /^log4j.appender.SOCKETHUB.Application=(.*)/m
          replace: "log4j.appender.SOCKETHUB.Application=zookeeper"
          append: true
        ,
          match: /^log4j.appender.SOCKETHUB.Port=(.*)/m
          replace: "log4j.appender.SOCKETHUB.Port=#{zookeeper.log4j.server_port}"
          append: true
        ,
          match: /^log4j.appender.SOCKETHUB.BufferSize=(.*)/m
          replace: "log4j.appender.SOCKETHUB.BufferSize=100"
          append: true
      # Append the configuration of the SocketAppender
      if zookeeper.log4j.remote_host && zookeeper.log4j.remote_port
        writes.push
          match: /^# Add SOCKET to rootLogger to send logs to the remote Logstash TCP Server(.*)/m
          replace: "\n#\n# Add SOCKET to rootLogger to send logs to the remote Logstash TCP Server\n#"
          append: true
        ,
          match: /^log4j.appender.SOCKET=(.*)/m
          replace: "log4j.appender.SOCKET=org.apache.log4j.net.SocketAppender"
          append: true
        ,
          match: /^log4j.appender.SOCKET.Application=(.*)/m
          replace: "log4j.appender.SOCKET.Application=zookeeper"
          append: true
        ,
          match: /^log4j.appender.SOCKET.RemoteHost=(.*)/m
          replace: "log4j.appender.SOCKET.RemoteHost=#{zookeeper.log4j.remote_host}"
          append: true
        ,
          match: /^log4j.appender.SOCKET.Port=(.*)/m
          replace: "log4j.appender.SOCKET.Port=#{zookeeper.log4j.remote_port}"
          append: true
        ,
          match: /^log4j.appender.SOCKET.ReconnectionDelay(.*)/m
          replace: "log4j.appender.SOCKET.ReconnectionDelay=10000"
          append: true
      @write
        destination: "#{zookeeper.conf_dir}/log4j.properties"
        source: "#{__dirname}/resources/log4j.properties"
        local_source: true
        write: writes

## Schedule Purge Transaction Logs

A ZooKeeper server will not remove old snapshots and log files when using the
default configuration (see autopurge below), this is the responsibility of the
operator.

The PurgeTxnLog utility implements a simple retention policy that administrators
can use. Its expected arguments are "dataLogDir [snapDir] -n count".

Note, Automatic purging of the snapshots and corresponding transaction logs was
introduced in version 3.4.0 and can be enabled via the following configuration
parameters autopurge.snapRetainCount and autopurge.purgeInterval.

```
/usr/bin/java \
  -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
  org.apache.zookeeper.server.PurgeTxnLog  /var/zookeeper/data/ -n 3
```

    module.exports.push header: "ZooKeeper Server # Schedule Purge", handler: ->
      {zookeeper} = @config.ryba
      return unless zookeeper.purge
      @cron_add
        cmd: """
        /usr/bin/java -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
          org.apache.zookeeper.server.PurgeTxnLog \
          #{zookeeper.config.dataLogDir or ''} #{zookeeper.config.dataDir} -n #{zookeeper.retention}
        """
        when: zookeeper.purge
        user: zookeeper.user.name

## Write myid

myid is a unique id that must be generated for each node of the zookeeper cluster

    module.exports.push header: 'ZooKeeper Server # Write myid', handler: ->
      {zookeeper, hadoop_group} = @config.ryba
      hosts = @hosts_with_module 'ryba/zookeeper/server'
      return if hosts.length is 1
      unless zookeeper.myid
        for host, i in hosts
          zookeeper.myid = i+1 if host is @config.host
      @write
        content: zookeeper.myid
        destination: "#{zookeeper.config['dataDir']}/myid"
        uid: zookeeper.user.name
        gid: hadoop_group.name

## Resources

*   [ZooKeeper Resilience](http://blog.cloudera.com/blog/2014/03/zookeeper-resilience-at-pinterest/)

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-zookeeper-1.html

## Dependencies

    quote = require 'regexp-quote'
