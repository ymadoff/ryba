
# Hadoop ZKFC Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/zookeeper/server/wait'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'
    module.exports.push require '../../lib/write_jaas'
    module.exports.push require('./index').configure

## IPTables

| Service   | Port | Proto  | Parameter                  |
|-----------|------|--------|----------------------------|
| namenode  | 8019  | tcp   | dfs.ha.zkfc.port           |

    module.exports.push name: 'ZKFC # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "ZKFC IPC" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Service

Install the "hadoop-hdfs-zkfc" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

    module.exports.push name: 'ZKFC # Service', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      ctx.hdp_service
        name: 'hadoop-hdfs-zkfc'
        version_name: 'hadoop-hdfs-namenode'
        write: [
          match: /^USER=".*?".*CONF_DIR.*$/mg
          replace: "USER=\"$SVC_USER\"; . $CONF_DIR/hadoop-env.sh # RYBA FIX rc.d"
          before: /^DAEMON=.*$/mg
        ,
          # HDP default is "/usr/lib/hadoop/sbin/hadoop-daemon.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HADOOP_HOME}/sbin/hadoop-daemon.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          match: /^PIDFILE=".*".*$/mg
          replace: "PIDFILE=\"$HADOOP_PID_DIR/hadoop-$HADOOP_IDENT_STRING-zkfc.pid\" # RYBA FIX rc.d"
        ]
        etc_default:
          'hadoop': true
          'hadoop-hdfs-zkfc':
            write: [
              match: /^export HADOOP_PID_DIR=.*$/m # HDP default is "/var/run/hadoop-hdfs"
              replace: "export HADOOP_PID_DIR=#{hdfs.pid_dir} # RYBA"
            ,
              match: /^export HADOOP_LOG_DIR=.*$/m # HDP default is "/var/log/hadoop-hdfs"
              replace: "export HADOOP_LOG_DIR=#{hdfs.log_dir} # RYBA"
            ,
              match: /^export HADOOP_IDENT_STRING=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_IDENT_STRING=#{hdfs.user.name} # RYBA"
            ]
      .then next

## Configure

    module.exports.push name: 'ZKFC # Configure', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      .then next

## HDFS ZKFC

Environment passed to the ZKFC before it starts.

    module.exports.push name: 'ZKFC # Opts', handler: (ctx, next) ->
      {zkfc, hadoop_conf_dir} = ctx.config.ryba
      ctx.write
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        match: /^export HADOOP_ZKFC_OPTS="(.*) \$\{HADOOP_ZKFC_OPTS\}" # RYBA ENV ".*?", DONT OVERWRITE/mg
        replace: "export HADOOP_ZKFC_OPTS=\"#{zkfc.opts} ${HADOOP_ZKFC_OPTS}\" # RYBA ENV \"ryba.zkfc.opts\", DONT OVERWRITE"
        append: true
        backup: true
      .then next

## Kerberos

Create a service principal for the ZKFC daemon to authenticate with Zookeeper.
The principal is named after "zkfc/#{ctx.config.host}@#{realm}" and its keytab
is stored as "/etc/security/keytabs/zkfc.service.keytab".

The Jaas file is registered as an Java property inside 'hadoop-env.sh' and is
stored as "/etc/hadoop/conf/zkfc.jaas"

    module.exports.push name: 'ZKFC # Kerberos', handler: (ctx, next) ->
      {realm, hadoop_group, hdfs, zkfc} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      zkfc_principal = zkfc.principal.replace '_HOST', ctx.config.host
      nn_principal = hdfs.site['dfs.namenode.kerberos.principal'].replace '_HOST', ctx.config.host
      ctx.krb5_addprinc
        principal: zkfc_principal
        keytab: zkfc.keytab
        randkey: true
        uid: hdfs.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
        if: zkfc_principal isnt nn_principal
      .krb5_addprinc
        principal: nn_principal
        keytab: hdfs.site['dfs.namenode.keytab.file']
        randkey: true
        uid: hdfs.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .write_jaas
        destination: zkfc.jaas_file
        content: Client:
          principal: zkfc_principal
          keyTab: zkfc.keytab
        uid: hdfs.user.name
        gid: hadoop_group.name
      .then next

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

    module.exports.push name: 'ZKFC # ZK Auth and ACL', handler: (ctx, next) ->
      {hadoop_conf_dir, core_site, hdfs, zkfc} = ctx.config.ryba
      modified = false
      acls = []
      # acls.push 'world:anyone:r'
      jaas_user = /^(.*?)[@\/]/.exec(zkfc.principal)?[1]
      acls.push "sasl:#{jaas_user}:cdrwa" if core_site['hadoop.security.authentication'] is 'kerberos'
      # acls.push "sasl:nn:cdrwa" if core_site['hadoop.security.authentication'] is 'kerberos'
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/core-site.xml"
        properties: core_site
        merge: true
        backup: true
      .write
        destination: "#{hadoop_conf_dir}/zk-auth.txt"
        content: if zkfc.digest.password then "digest:#{zkfc.digest.name}:#{zkfc.digest.password}" else ""
        uid: hdfs.user.name
        gid: hdfs.group.name
        mode: 0o0700
      .execute
        cmd: """
        export ZK_HOME=/usr/hdp/current/zookeeper-client/
        java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider #{zkfc.digest.name}:#{zkfc.digest.password}
        """
        if: !!zkfc.digest.password
      , (err, generated, stdout) ->
        return next err if err
        return unless generated
        digest = match[1] if match = /\->(.*)/.exec(stdout)
        throw Error "Failed to get digest" unless digest
        acls.push "digest:#{digest}:cdrwa"
      .write
        destination: "#{hadoop_conf_dir}/zk-acl.txt"
        content: acls.join ','
        uid: hdfs.user.name
        gid: hdfs.group.name
        mode: 0o0600
      .then next

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

    module.exports.push name: 'ZKFC # SSH Fencing', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, ssh_fencing, hadoop_group} = ctx.config.ryba
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      ctx
      .mkdir
        destination: "#{hdfs.user.home}/.ssh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o700
      .upload
        source: "#{ssh_fencing.private_key}"
        destination: "#{hdfs.user.home}/.ssh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o600
      .upload
        source: "#{ssh_fencing.public_key}"
        destination: "#{hdfs.user.home}/.ssh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o655
      .call (_, callback) ->
        fs.readFile "#{ssh_fencing.public_key}", (err, content) ->
          return callback err if err
          ctx.write
            destination: "#{hdfs.user.home}/.ssh/authorized_keys"
            content: content
            append: true
            uid: hdfs.user.name
            gid: hadoop_group.name
            mode: 0o600
          , (err, written) ->
            return callback err if err
            modified = true if written
            ctx.fs.readFile '/etc/security/access.conf', (err, source) ->
              return callback err if err
              content = []
              exclude = ///^\-\s?:\s?(ALL|#{hdfs.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
              include = ///^\+\s?:\s?(#{hdfs.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
              included = false
              for line, i in source = source.split /\r\n|[\n\r\u0085\u2028\u2029]/g
                if match = include.exec line
                  included = true # we shall also check if the ip/fqdn match in origin
                if not included and match = exclude.exec line
                  nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
                  content.push "+ : #{hdfs.user.name} : #{nn_hosts.join ','}"
                content.push line
              return callback null, false if content.length is source.length
              ctx.write
                destination: '/etc/security/access.conf'
                content: content.join '\n'
              , callback
      .then next

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

    module.exports.push name: 'ZKFC # Format ZK', timeout: -1, handler: (ctx, next) ->
      {hdfs, active_nn_host} = ctx.config.ryba
      return next() unless active_nn_host is ctx.config.host
      return next() unless hdfs.site['dfs.ha.automatic-failover.enabled'] = 'true'
      ctx.execute
        cmd: "yes n | hdfs zkfc -formatZK"
        code_skipped: 2
      , next


## Dependencies

    fs = require 'fs'
    lifecycle = require '../../lib/lifecycle'
    mkcmd = require '../../lib/mkcmd'
