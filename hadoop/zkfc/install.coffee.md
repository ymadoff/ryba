
# Hadoop ZKFC Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/zookeeper/server_wait'
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
      , next

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
      , next

## Configure

    module.exports.push name: 'ZKFC # Configure', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      , next

## HDFS ZKFC

Environment passed to the ZKFC before it starts.

    module.exports.push name: 'HDFS ZKFC # Opts', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir} = ctx.config.ryba
      ctx.write
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        match: /^export HADOOP_ZKFC_OPTS="(.*) \$\{HADOOP_ZKFC_OPTS\}" # RYBA ENV ".*?", DONT OVERWRITE/mg
        replace: "export HADOOP_ZKFC_OPTS=\"#{hdfs.zkfc_opts} ${HADOOP_ZKFC_OPTS}\" # RYBA ENV \"ryba.hdfs.zkfc_opts\", DONT OVERWRITE"
        append: true
        backup: true
      , next

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{ctx.config.host}@#{realm}".

    module.exports.push name: 'HDFS ZKFC # Kerberos', handler: (ctx, next) ->
      {realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "nn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nn.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Kerberos JAAS

Secure the Zookeeper connection with JAAS.

    module.exports.push name: 'HDFS ZKFC # Kerberos JAAS', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group, realm} = ctx.config.ryba
      ctx.write_jaas
        destination: "#{hadoop_conf_dir}/hdfs-zkfc.jaas"
        content: Client:
          principal: "nn/#{ctx.config.host}@#{realm}"
          keyTab: "/etc/security/keytabs/nn.service.keytab"
        uid: hdfs.user.name
        gid: hadoop_group.name
      , next

## ZK Auth and ACL

Secure the Zookeeper connection with JAAS. In a Kerberos cluster, the SASL
provider is configured with the NameNode principal. The digest provider may also
be configured if the property "ryba.hdfs.zkfc_digest.password" is set.

The permissions for each provider is "cdrwa", for example:

```
sasl:nn:cdrwa
digest:hdfs-zkfcs:KX44kC/I5PA29+qXVfm4lWRm15c=:cdrwa
```

Note, we didnt test a scenario where the cluster is not secured and the digest
isn't set. Probably the default acl "world:anyone:cdrwa" is used.

http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html#Securing_access_to_ZooKeeper

    module.exports.push name: 'HDFS ZKFC # ZK Auth and ACL', handler: (ctx, next) ->
      {hadoop_conf_dir, core_site, hdfs} = ctx.config.ryba
      modified = false
      acls = []
      # acls.push 'world:anyone:r'
      acls.push "sasl:nn:cdrwa" if core_site['hadoop.security.authentication'] is 'kerberos'
      do_core = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties: core_site
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_auth()
      do_auth = ->
        content = if hdfs.zkfc_digest.password
        then "digest:#{hdfs.zkfc_digest.name}:#{hdfs.zkfc_digest.password}"
        else ""
        ctx.write [
          destination: "#{hadoop_conf_dir}/zk-auth.txt"
          content: content
          uid: hdfs.user.name
          gid: hdfs.group.name
          mode: 0o0700
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_generate()
      do_generate = ->
        ctx.execute
          cmd: """
          export ZK_HOME=/usr/hdp/current/zookeeper-client/
          java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider #{hdfs.zkfc_digest.name}:#{hdfs.zkfc_digest.password}
          """
          if: hdfs.zkfc_digest.password
        , (err, generated, stdout) ->
          return next err if err
          return do_acl() unless generated
          digest = match[1] if match = /\->(.*)/.exec(stdout)
          return next Error "Failed to get digest" unless digest
          acls.push "digest:#{digest}:cdrwa"
          do_acl()
      do_acl = ->
        ctx.write
          destination: "#{hadoop_conf_dir}/zk-acl.txt"
          content: acls.join ','
          uid: hdfs.user.name
          gid: hdfs.group.name
          mode: 0o0600
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_core()

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
      modified = false
      do_mkdir = ->
        ctx.mkdir
          destination: "#{hdfs.user.home}/.ssh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o700
        , (err, created) ->
          return next err if err
          do_upload_keys()
      do_upload_keys = ->
        ctx.upload [
          source: "#{ssh_fencing.private_key}"
          destination: "#{hdfs.user.home}/.ssh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o600
        ,
          source: "#{ssh_fencing.public_key}"
          destination: "#{hdfs.user.home}/.ssh"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o655
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_authorized()
      do_authorized = ->
        fs.readFile "#{ssh_fencing.public_key}", (err, content) ->
          return next err if err
          ctx.write
            destination: "#{hdfs.user.home}/.ssh/authorized_keys"
            content: content
            append: true
            uid: hdfs.user.name
            gid: hadoop_group.name
            mode: 0o600
          , (err, written) ->
            return next err if err
            modified = true if written
            do_access()
      do_access = ->
        ctx.fs.readFile '/etc/security/access.conf', (err, source) ->
          return next err if err
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
          return do_end() if content.length is source.length
          ctx.write
            destination: '/etc/security/access.conf'
            content: content.join '\n'
          , (err, written) ->
            return next err if err
            modified = true if written
            do_end()
      do_end = ->
          next null, modified
      do_mkdir()

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

    module.exports.push name: 'ZKFC # HA Auto Failover', timeout: -1, handler: (ctx, next) ->
      {hdfs, active_nn_host} = ctx.config.ryba
      return next() unless hdfs.site['dfs.ha.automatic-failover.enabled'] = 'true'
      do_zkfc_active = ->
        # About "formatZK"
        # If no created, no configuration asked and exit code is 0
        # If already exist, configuration is refused and exit code is 2
        # About "transitionToActive"
        # Seems like the first time, starting zkfc dont active the nn, so we force it
        ctx.execute
          cmd: "yes n | hdfs zkfc -formatZK"
          code_skipped: 2
        , (err, formated) ->
          return next err if err
          ctx.log "Is Zookeeper already formated: #{formated}"
          lifecycle.zkfc_start ctx, (err, started) ->
            next null, formated or started
      do_zkfc_standby = ->
        ctx.log "Wait for active NameNode to take leadership"
        ctx.waitForExecution
          # hdfs haadmin -getServiceState hadoop1
          cmd: mkcmd.hdfs ctx, "hdfs haadmin -getServiceState #{active_nn_host.split('.')[0]}"
          code_skipped: 255
        , (err, stdout) ->
          return next err if err
          lifecycle.zkfc_start ctx, next
      if active_nn_host is ctx.config.host
      then do_zkfc_active()
      else do_zkfc_standby()

## Dependencies

    fs = require 'fs'
    lifecycle = require '../../lib/lifecycle'
    mkcmd = require '../../lib/mkcmd'




