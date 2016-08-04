
# Zookeeper Server Install

    module.exports = header: 'ZooKeeper Server Install', handler: ->
      {zookeeper, hadoop_group, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'write_jaas', 'ryba/lib/write_jaas'

## Wait

      @call once: true, 'masson/core/krb5_client/wait'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

      @group zookeeper.group
      @group hadoop_group
      @user zookeeper.user

## IPTables

| Service    | Port | Proto  | Parameter          |
|------------|------|--------|--------------------|
| zookeeper  | 2181 | tcp    | zookeeper.port     |
| zookeeper  | 2888 | tcp    | -                  |
| zookeeper  | 3888 | tcp    | -                  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [
          { chain: 'INPUT', jump: 'ACCEPT', dport: zookeeper.port, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Client" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 2888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Peer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3888, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Leader" }
      ]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(zookeeper.env["JMXPORT"],10), protocol: 'tcp', state: 'NEW', comment: "Zookeeper JMX" } if zookeeper.env["JMXPORT"]?
      @iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'nc' # Used by check
        @service
          name: 'zookeeper-server'
        @hdp_select
          name: 'zookeeper-server'
        @hdp_select
          name: 'zookeeper-client'
        @write
          source: "#{__dirname}/resources/zookeeper"
          local_source: true
          target: '/etc/init.d/zookeeper-server'
          mode: 0o0755
          unlink: true

## Kerberos

      @call once: true, 'masson/core/krb5_client/wait'
      @call header: 'Kerberos', handler: ->
        @krb5_addprinc krb5,
          principal: "zookeeper/#{@config.host}@#{realm}"
          randkey: true
          keytab: '/etc/security/keytabs/zookeeper.service.keytab'
          uid: zookeeper.user.name
          gid: hadoop_group.name
        @write_jaas
          target: '/etc/zookeeper/conf/zookeeper-server.jaas'
          content: Server:
            principal: "zookeeper/#{@config.host}@#{realm}"
            keyTab: '/etc/security/keytabs/zookeeper.service.keytab'
          uid: zookeeper.user.name
          gid: hadoop_group.name
        @write_jaas
          target: "#{zookeeper.conf_dir}/zookeeper-client.jaas"
          content: Client:
            useTicketCache: true
          mode: 0o0644

## Layout

Create the data, pid and log directories with the correct permissions and
ownerships.

      @call header: 'Layout', handler: ->
        @mkdir
          target: zookeeper.config['dataDir']
          uid: zookeeper.user.name
          gid: hadoop_group.name
          mode: 0o755
        @mkdir
          target: zookeeper.pid_dir
          uid: zookeeper.user.name
          gid: zookeeper.group.name
          mode: 0o755
        @mkdir
          target: zookeeper.log_dir
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

      @execute
        header: 'Generate Super User'
        if: zookeeper.superuser.password
        cmd: """
        ZK_HOME=/usr/hdp/current/zookeeper-client/
        java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:#{zookeeper.superuser.password}
        """
      , (err, generated, stdout) ->
        throw err if err
        return unless generated # probably because password not set
        digest = match[1] if match = /\->(.*)/.exec(stdout)
        throw Error "Failed to get digest: bad output" unless digest
        zookeeper.env['SERVER_JVMFLAGS'] = "-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} #{zookeeper.env['SERVER_JVMFLAGS']}"

## Environment

Note, environment is enriched at runtime if a super user is generated
(see above).

      @write
        header: 'Environment'
        target: "#{zookeeper.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of zookeeper.env).join '\n'
        backup: true
        eof: true

## Configure

Update the file "zoo.cfg" with the properties defined by the
"ryba.zookeeper.config" configuration.

      @write_properties
        header: 'Configure'
        target: "#{zookeeper.conf_dir}/zoo.cfg"
        content: zookeeper.config
        backup: true

## Log4J

Write the ZooKeeper logging configuration file.

      @write_properties
        header: 'Log4J'
        target: "#{zookeeper.conf_dir}/log4j.properties"
        content: zookeeper.log4j.config
        backup: true

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

      @cron_add
        header: 'Schedule Purge'
        if: zookeeper.purge
        cmd: """
        /usr/bin/java -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
          org.apache.zookeeper.server.PurgeTxnLog \
          #{zookeeper.config.dataLogDir or ''} #{zookeeper.config.dataDir} -n #{zookeeper.retention}
        """
        when: zookeeper.purge
        user: zookeeper.user.name

## Write myid

myid is a unique id that must be generated for each node of the zookeeper cluster

      zk_ctxs = @contexts 'ryba/zookeeper/server'
      return if zk_ctxs.length is 1
      unless zookeeper.myid
        for zk_ctx, i in zk_ctxs
          zookeeper.myid = i+1 if zk_ctx.config.host is @config.host
      @write
        header: 'Write myid'
        content: zookeeper.myid
        target: "#{zookeeper.config['dataDir']}/myid"
        uid: zookeeper.user.name
        gid: hadoop_group.name

## Resources

*   [ZooKeeper Resilience](http://blog.cloudera.com/blog/2014/03/zookeeper-resilience-at-pinterest/)

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-zookeeper-1.html

## Dependencies

    quote = require 'regexp-quote'
