
# Hadoop HDFS NameNode Install

This implementation configure an HA HDFS cluster, using the [Quorum Journal Manager (QJM)](qjm)
feature  to share edit logs between the Active and Standby NameNodes. Hortonworks
provides [instructions to rollback a HA installation][rollback] that apply to Ambari.

Worth to investigate:

*   [RPC Congestion Control with FairCallQueue](https://issues.apache.org/jira/browse/HADOOP-9640)
*   [RPC fair share](https://issues.apache.org/jira/browse/HADOOP-10598)

[rollback]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.3/bk_Monitoring_Hadoop_Book/content/monitor-ha-undoing_2x.html

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'

## Configuration

The NameNode doesn't define new configuration properties. However, it uses properties
define inside the "ryba/hadoop/hdfs" and "masson/core/nc" modules.

    module.exports.push require('./hdfs_nn').configure

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |
| namenode  | 8019  | tcp    | dfs.ha.zkfc.port           |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDFS NN # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50070, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50470, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8020, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 9000, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Startup

Install and configure the startup script in "/etc/init.d/hadoop-hdfs-namenode".

    module.exports.push name: 'HDFS NN # Startup', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service [
          {name: 'hadoop-hdfs-namenode', startup: true}
          {name: 'hadoop-hdfs-zkfc', startup: true}
        ], (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write [
          destination: '/etc/init.d/hadoop-hdfs-namenode'
          write: [
            {match: /^PIDFILE=".*"$/m, replace: "PIDFILE=\"#{hdfs.pid_dir}/$SVC_USER/hadoop-hdfs-namenode.pid\""}
            {match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m, replace: "$1 -u $SVC_USER $2"}]
        ,
          destination: '/etc/init.d/hadoop-hdfs-zkfc'
          write: [
            {match: /^PIDFILE=".*"$/m, replace: "PIDFILE=\"#{hdfs.pid_dir}/$SVC_USER/hadoop-hdfs-zkfc.pid\""}
            {match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m, replace: "$1 -u $SVC_USER $2"}]
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

    module.exports.push name: 'HDFS NN # Layout', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      ctx.mkdir [
        destination: hdfs.site['dfs.namenode.name.dir'].split ','
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        parent: true
      ,
        destination: "#{hdfs.pid_dir}/#{hdfs.user.name}"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
      ], next

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{ctx.config.host}@#{realm}".

    module.exports.push name: 'HDFS NN # Kerberos', handler: (ctx, next) ->
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

# Opts

Environment passed to the NameNode before it starts.   

    module.exports.push name: 'HDFS NN # Opts', handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs} = ctx.config.ryba
      return next() unless hdfs.namenode_opts
      ctx.write
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        match: /^export HADOOP_NAMENODE_OPTS="(.*) \$\{HADOOP_NAMENODE_OPTS\}" # GENERATED BY RYBA, DONT OVEWRITE/mg
        replace: "export HADOOP_NAMENODE_OPTS=\"#{hdfs.namenode_opts} ${HADOOP_NAMENODE_OPTS}\" # GENERATED BY RYBA, DONT OVEWRITE"
        before: /^export HADOOP_NAMENODE_OPTS=.*$/mg
        backup: true
      , next

# Configure

    module.exports.push name: 'HDFS NN # Configure', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      , next

# Slaves

The conf/slaves file should contain the hostname of every machine
in the cluster which should start TaskTracker and DataNode daemons.

    module.exports.push name: 'HDFS NN # Slaves', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      datanodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
      ctx.write
        content: "#{datanodes.join '\n'}"
        destination: "#{hadoop_conf_dir}/slaves"
        eof: true
      , next

# SSH Fencing

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

    module.exports.push name: 'HDFS NN # SSH Fencing', handler: (ctx, next) ->
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

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

    module.exports.push name: 'HDFS NN # Format', timeout: -1, handler: (ctx, next) ->
      {hdfs, active_nn, nameservice} = ctx.config.ryba
      any_dfs_name_dir = hdfs.site['dfs.namenode.name.dir'].split(',')[0]
      unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        ctx.execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -format\""
          not_if_exists: "#{any_dfs_name_dir}/current/VERSION"
        , next
      else
        # Shall only be executed on the leader namenode
        return next() unless active_nn
        journalnodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
        # all the JournalNodes shall be started
        ctx.waitIsOpen journalnodes, 8485, (err) ->
          return next err if err
          ctx.execute
            # yes 'Y' | su -l hdfs -c "hdfs namenode -format -clusterId torval"
            cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -format -clusterId #{nameservice}\""
            # /hadoop/hdfs/namenode/current/VERSION
            not_if_exists: "#{any_dfs_name_dir}/current/VERSION"
          , next

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on a non active NameNode.

    module.exports.push name: 'HDFS NN # HA Init Standby', timeout: -1, handler: (ctx, next) ->
      # Shall only be executed on the leader namenode
      {active_nn, active_nn_host} = ctx.config.ryba
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      return next() if active_nn
      do_wait = ->
        ctx.waitIsOpen active_nn_host, 8020, (err) ->
          return next err if err
          do_init()
      do_init = ->
        ctx.execute
          # su -l hdfs -c "hdfs namenode -bootstrapStandby -nonInteractive"
          cmd: "su -l hdfs -c \"hdfs namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5
        , next
      do_wait()

## Zookeeper JAAS

Secure the Zookeeper connection with JAAS.

    module.exports.push name: 'HDFS NN # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group, zkfc_password} = ctx.config.ryba
      modified = false
      do_core = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties:
            'ha.zookeeper.auth': "@#{hadoop_conf_dir}/zk-auth.txt"
            'ha.zookeeper.acl': "@#{hadoop_conf_dir}/zk-acl.txt"
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_content()
      do_content = ->
        ctx.write [
          destination: "#{hadoop_conf_dir}/zk-auth.txt"
          content: "digest:hdfs-zkfcs:#{zkfc_password}"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o0700
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_generate()
      do_generate = ->
          ctx.execute
            cmd: """
            export ZK_HOME=/usr/lib/zookeeper/
            java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider hdfs-zkfcs:#{zkfc_password}
            """
          , (err, _, stdout) ->
            digest = match[1] if match = /\->(.*)/.exec(stdout)
            return next Error "Failed to get digest" unless digest
            ctx.write
              destination: '/etc/hadoop/conf/zk-acl.txt'
              content: "digest:#{digest}:rwcda"
            , (err, written) ->
              return next err if err
              modified = true if written
              do_end()
      do_end = ->
        next null, modified
      do_core()

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

    module.exports.push name: 'HDFS NN # HA Auto Failover', timeout: -1, handler: (ctx, next) ->
      {hadoop_conf_dir, active_nn, active_nn_host} = ctx.config.ryba
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      zookeepers = ctx.hosts_with_module 'ryba/zookeeper/server'
      modified = false
      do_hdfs = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/hdfs-site.xml"
          properties: 'dfs.ha.automatic-failover.enabled': 'true'
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_core()
      do_core = ->
        quorum = zookeepers.map( (host) -> "#{host}:2181" ).join ','
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties: 'ha.zookeeper.quorum': quorum
          merge: true
          backup: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_wait()
      do_wait = ->
        ctx.waitIsOpen zookeepers, 2181, (err) ->
          return next err if err
          setTimeout ->
            do_zkfc()
          , 2000
      do_zkfc = ->
        if active_nn
        then do_zkfc_active()
        else do_zkfc_standby()
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
      do_hdfs()

## Module Dependencies

    fs = require 'fs'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'
    each = require 'each'


