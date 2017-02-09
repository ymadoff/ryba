
# Hadoop ZKFC Install

    module.exports = header: 'HDFS ZKFC Install', handler: ->
      {ryba} = @config
      {hdfs, zkfc, active_nn_host} = ryba
      {hdfs, zkfc, core_site, hadoop_group} = ryba
      {realm, hadoop_group, hdfs, zkfc} = ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      {hdfs, core_site, zkfc} = ryba
      {hdfs, ssh_fencing, hadoop_group} = ryba

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## IPTables

| Service   | Port | Proto  | Parameter                  |
|-----------|------|--------|----------------------------|
| namenode  | 8019  | tcp   | dfs.ha.zkfc.port           |

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hdfs.nn.site['dfs.ha.zkfc.port'], protocol: 'tcp', state: 'NEW', comment: "ZKFC IPC" }
        ]
        if: @config.iptables.action is 'start'

## Packages

Install the "hadoop-hdfs-zkfc" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

      @call header: 'Packages', handler: ->
        @service
          name: 'hadoop-hdfs-zkfc'
        @hdp_select
          # name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-namenode'
        @service.init
          target: '/etc/init.d/hadoop-hdfs-zkfc'
          source: "#{__dirname}/../resources/hadoop-hdfs-zkfc.j2"
          local_source: true
          context: @config
          mode: 0o0755
        @execute
          cmd: "service hadoop-hdfs-zkfc restart"
          if: -> @status -3

## Configure

      @call header: 'Configure', timeout: -1, handler: ->
        @mkdir
          target: "#{zkfc.conf_dir}"
        @hconfigure
          target: "#{zkfc.conf_dir}/core-site.xml"
          properties: core_site
          backup: true
        @hconfigure
          target: "#{zkfc.conf_dir}/hdfs-site.xml"
          source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
          local_source: true
          properties: hdfs.nn.site
          uid: hdfs.user.name
          gid: hadoop_group.name
          backup: true
        @render
          header: 'Environment'
          target: "#{zkfc.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local_source: true
          context:
            HADOOP_HEAPSIZE: ryba.hadoop_heap
            HADOOP_LOG_DIR: ryba.hdfs.log_dir
            HADOOP_PID_DIR: ryba.hdfs.pid_dir
            HADOOP_OPTS: ryba.hadoop_opts
            ZKFC_OPTS: ryba.zkfc.opts
            java_home: @config.java.java_home
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        @file
          header: 'Log4j'
          target: "#{zkfc.conf_dir}/log4j.properties"
          source: "#{__dirname}/../resources/log4j.properties"
          local_source: true

## Kerberos

Create a service principal for the ZKFC daemon to authenticate with Zookeeper.
The principal is named after "zkfc/#{@config.host}@#{realm}" and its keytab
is stored as "/etc/security/keytabs/zkfc.service.keytab".

The Jaas file is registered as an Java property inside 'hadoop-env.sh' and is
stored as "/etc/hadoop/conf/zkfc.jaas"

      @call header: 'Kerberos', handler: ->
        zkfc_principal = zkfc.principal.replace '_HOST', @config.host
        nn_principal = hdfs.nn.site['dfs.namenode.kerberos.principal'].replace '_HOST', @config.host
        @krb5_addprinc krb5,
          principal: zkfc_principal
          keytab: zkfc.keytab
          randkey: true
          uid: hdfs.user.name
          gid: hadoop_group.name
          if: zkfc_principal isnt nn_principal
        @krb5_addprinc krb5,
          principal: nn_principal
          keytab: hdfs.nn.site['dfs.namenode.keytab.file']
          randkey: true
          uid: hdfs.user.name
          gid: hadoop_group.name
        @file.jaas
          target: zkfc.jaas_file
          content: Client:
            principal: zkfc_principal
            keyTab: zkfc.keytab
          uid: hdfs.user.name
          gid: hadoop_group.name

## ZK Auth and ACL

Secure the Zookeeper connection with JAAS. In a Kerberos cluster, the SASL
provider is configured with the NameNode principal. The digest provider may also
be configured if the property "ryba.zkfc.digest.password" is set.

The permissions for each provider is "cdrwa", for example:

```
sasl:nn:cdrwa
digest:hdfs-zkfcs:KX44kC/I5PA29+qXVfm4lWRm15c=:cdrwa
```

Note, we didnt test a scenario where the cluster is not secured and the digest
isn't set. Probably the default acl "world:anyone:cdrwa" is used.

http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html#Securing_access_to_ZooKeeper

If you need to change the acl manually inside zookeeper, you can use this
command as an example:

```
setAcl /hadoop-ha sasl:zkfc:cdrwa,sasl:nn:cdrwa,digest:zkfc:ePBwNWc34ehcTu1FTNI7KankRXQ=:cdrwa
```

      @call header: 'ZK Auth and ACL', handler: ->
        acls = []
        # acls.push 'world:anyone:r'
        jaas_user = /^(.*?)[@\/]/.exec(zkfc.principal)?[1]
        acls.push "sasl:#{jaas_user}:cdrwa" if core_site['hadoop.security.authentication'] is 'kerberos'
        @file
          target: "#{zkfc.conf_dir}/zk-auth.txt"
          content: if zkfc.digest.password then "digest:#{zkfc.digest.name}:#{zkfc.digest.password}" else ""
          uid: hdfs.user.name
          gid: hdfs.group.name
          mode: 0o0700
        @execute
          cmd: """
          export ZK_HOME=/usr/hdp/current/zookeeper-client/
          java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider #{zkfc.digest.name}:#{zkfc.digest.password}
          """
          shy: true
          if: !!zkfc.digest.password
        , (err, generated, stdout) ->
          throw err if err
          return unless generated
          digest = match[1] if match = /\->(.*)/.exec(stdout)
          throw Error "Failed to get digest" unless digest
          acls.push "digest:#{digest}:cdrwa"
        @call ->
          @file
            target: "#{zkfc.conf_dir}/zk-acl.txt"
            content: acls.join ','
            uid: hdfs.user.name
            gid: hdfs.group.name
            mode: 0o0600

## SSH Fencing

Implement the SSH fencing strategy on each NameNode. To achieve this, the
"hdfs-site.xml" file is updated with the "dfs.ha.fencing.methods" and
"dfs.ha.fencing.ssh.private-key-files" properties.

For SSH fencing to work, the HDFS user must be able to log for each NameNode
into any other NameNode. Thus, the public and private SSH keys of the
HDFS user are deployed inside his "~/.ssh" folder and the
"~/.ssh/authorized_keys" file is updated accordingly.

We also make sure SSH access is not blocked by a rule defined
inside "/etc/security/access.conf". A specific rule for the HDFS user is
inserted if ALL users or the HDFS user access is denied.

      @call
        header: 'SSH Fencing'
        # if: -> @contexts('ryba/hadoop/hdfs_nn').length > 1
        handler: ->
          @mkdir
            target: "#{hdfs.user.home}/.ssh"
            uid: hdfs.user.name
            gid: hadoop_group.name
            mode: 0o700
          @file.download
            source: "#{ssh_fencing.private_key}"
            target: "#{hdfs.user.home}/.ssh/id_rsa"
            uid: hdfs.user.name
            gid: hadoop_group.name
            mode: 0o600
          @file.download
            source: "#{ssh_fencing.public_key}"
            target: "#{hdfs.user.home}/.ssh/id_rsa.pub"
            uid: hdfs.user.name
            gid: hadoop_group.name
            mode: 0o644
          @call (_, callback) ->
            fs.readFile "#{ssh_fencing.public_key}", (err, content) =>
              return callback err if err
              @file
                target: "#{hdfs.user.home}/.ssh/authorized_keys"
                content: content
                append: true
                uid: hdfs.user.name
                gid: hadoop_group.name
                mode: 0o600
              , (err, written) =>
                return callback err if err
                @fs.readFile '/etc/security/access.conf', 'utf8', (err, source) =>
                  return callback err if err
                  content = []
                  exclude = ///^\-\s?:\s?(ALL|#{hdfs.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
                  include = ///^\+\s?:\s?(#{hdfs.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
                  included = false
                  for line, i in source = source.split /\r\n|[\n\r\u0085\u2028\u2029]/g
                    if match = include.exec line
                      included = true # we shall also check if the ip/fqdn match in origin
                    if not included and match = exclude.exec line
                      nn_hosts = @contexts('ryba/hadoop/hdfs_nn').map (ctx) -> ctx.config.host
                      content.push "+ : #{hdfs.user.name} : #{nn_hosts.join ','}"
                    content.push line
                  return callback null, false if content.length is source.length
                  @file
                    target: '/etc/security/access.conf'
                    content: content.join '\n'
                  .then callback

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

      @call once: true, 'ryba/zookeeper/server/wait'
      @execute
        header: 'Format ZK'
        timeout: -1
        if: [
          -> active_nn_host is @config.host
          -> hdfs.nn.site['dfs.ha.automatic-failover.enabled'] = 'true'
        ]
        cmd: "yes n | hdfs --config #{zkfc.conf_dir} zkfc -formatZK"
        code_skipped: 2

## Dependencies

    fs = require 'fs'
    mkcmd = require '../../lib/mkcmd'
