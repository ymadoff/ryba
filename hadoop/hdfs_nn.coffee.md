---
title: HDP HDFS NameNode
module: ryba/hadoop/hdfs_nn
layout: module
---

# HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

This implementation configure an HA HDFS cluster, using the [Quorum Journal Manager (QJM)](qjm)
feature  to share edit logs between the Active and Standby NameNodes. Hortonworks
provides [instructions to rollback a HA installation][rollback] that apply to Ambari.

[rollback]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.3/bk_Monitoring_Hadoop_Book/content/monitor-ha-undoing_2x.html

    fs = require 'fs'
    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    each = require 'each'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'

## Configuration

The NameNode doesn't define new configuration properties. However, it uses properties
define inside the "ryba/hadoop/hdfs" and "masson/core/nc" modules.

    module.exports.push (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./hdfs').configure ctx
      throw Error "Missing \"hdp.zkfc_password\" property" unless ctx.config.hdp.zkfc_password
      # require('masson/core/iptables').configure ctx

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |
| namenode  | 8019  | tcp    | dfs.ha.zkfc.port           |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP HDFS NN # IPTables', callback: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50070, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50470, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8020, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 9000, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Startup

Install and configure the startup script in "/etc/init.d/hadoop-hdfs-namenode".

    module.exports.push name: 'HDP HDFS NN # Startup', callback: (ctx, next) ->
      {hdfs_pid_dir} = ctx.config.hdp
      modified = false
      do_install = ->
        ctx.service [
          name: 'hadoop-hdfs-namenode'
          startup: true
        ,
          name: 'hadoop-hdfs-zkfc'
          startup: true
        ], (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write [
          destination: '/etc/init.d/hadoop-hdfs-namenode'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{hdfs_pid_dir}/$SVC_USER/hadoop-hdfs-namenode.pid\""
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        ,
          destination: '/etc/init.d/hadoop-hdfs-zkfc'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{hdfs_pid_dir}/$SVC_USER/hadoop-hdfs-zkfc.pid\""
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_install()

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

    module.exports.push name: 'HDP HDFS NN # Layout', timeout: -1, callback: (ctx, next) ->
      {hdfs_site, hdfs_pid_dir, hdfs_user, hadoop_group} = ctx.config.hdp
      ctx.mkdir [
        destination: hdfs_site['dfs.namenode.name.dir'].split ','
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user.name}"
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ], (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{ctx.config.host}@#{realm}".

    module.exports.push name: 'HDP HDFS NN # Kerberos', callback: (ctx, next) ->
      {realm} = ctx.config.hdp
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
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

# Configure HA

Update "hdfs-site.xml" with HA configuration. The inserted properties are
similar than the ones for a client or slave configuration with the addtionnal
"dfs.namenode.shared.edits.dir" and "dfs.namenode.shared.edits.dir" properties.

    module.exports.push name: 'HDP HDFS NN # Configure HA', callback: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config} = ctx.config.hdp
      journalnodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
      ha_client_config['dfs.namenode.shared.edits.dir'] = (for jn in journalnodes then "#{jn}:8485").join ';'
      ha_client_config['dfs.namenode.shared.edits.dir'] = "qjournal://#{ha_client_config['dfs.namenode.shared.edits.dir']}/#{ha_client_config['dfs.nameservices']}"
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: ha_client_config
        merge: true
      , (err, configured) ->
        return next err, if configured then ctx.OK else ctx.PASS

# SSH Fencing

Implement the SSH fencing strategy on each NameNode. To achieve this, we update the "hdfs-site.xml" file
with the "dfs.ha.fencing.methods" and "dfs.ha.fencing.ssh.private-key-files" properties. For SSH fencing
to work, the HDFS usermust be able to log for each NameNode into any other NameNode. Thus, we deploy the
public and private SSH keys for the HDFS user inside his "~/.ssh" folder and update the
"~/.ssh/authorized_keys" file accordingly.

    module.exports.push name: 'HDP HDFS NN # SSH Fencing', callback: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config, ssh_fencing, hdfs_user, hadoop_group} = ctx.config.hdp
      hdfs_home = '/var/lib/hadoop-hdfs'
      modified = false
      ha_client_config['dfs.ha.fencing.methods'] = 'sshfence(hdfs)'
      ha_client_config['dfs.ha.fencing.ssh.private-key-files'] = '#{hdfs_home}/.ssh/id_rsa'
      do_mkdir = ->
        ctx.mkdir
          destination: "#{hdfs_home}/.ssh"
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o700
        , (err, created) ->
          return next err if err
          do_upload_keys()
      do_upload_keys = ->
        ctx.upload [
          source: "#{ssh_fencing.private_key}"
          destination: "#{hdfs_home}/.ssh"
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o600
        ,
          source: "#{ssh_fencing.public_key}"
          destination: "#{hdfs_home}/.ssh"
          uid: hdfs_user.name
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
            destination: "#{hdfs_home}/.ssh/authorized_keys"
            content: content
            append: true
            uid: hdfs_user.name
            gid: hadoop_group.name
            mode: 0o600
          , (err, written) ->
            return next err if err
            modified = true if written
            do_configure()
      do_configure = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/hdfs-site.xml"
          properties: ha_client_config
          merge: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_end()
      do_end = ->
          next null, if modified then ctx.OK else ctx.PASS
      do_mkdir()

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

    module.exports.push name: 'HDP HDFS NN # Format', timeout: -1, callback: (ctx, next) ->
      {active_nn, hdfs_site, hdfs_user, format, nameservice} = ctx.config.hdp
      return next() unless format
      # Shall only be executed on the leader namenode
      return next null, ctx.INAPPLICABLE unless active_nn
      journalnodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
      any_dfs_name_dir = hdfs_site['dfs.namenode.name.dir'].split(',')[0]
      # all the JournalNodes shall be started
      ctx.waitIsOpen journalnodes, 8485, (err) ->
        return next err if err
        ctx.execute
          # yes 'Y' | su -l hdfs -c "hdfs namenode -format -clusterId torval"
          cmd: "su -l #{hdfs_user.name} -c \"hdfs namenode -format -clusterId #{nameservice}\""
          # /hadoop/hdfs/namenode/current/VERSION
          not_if_exists: "#{any_dfs_name_dir}/current/VERSION"
        , (err, executed) ->
          return next err if err
          return next null, if executed then ctx.OK else ctx.PASS
          lifecycle.nn_start ctx, (err, started) ->
            return next err, ctx.OK

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on a non active NameNode.

    module.exports.push name: 'HDP HDFS NN # HA Init Standby NameNodes', timeout: -1, callback: (ctx, next) ->
      # Shall only be executed on the leader namenode
      {active_nn, active_nn_host} = ctx.config.hdp
      return next null, ctx.INAPPLICABLE if active_nn
      do_wait = ->
        ctx.waitIsOpen active_nn_host, 8020, (err) ->
          return next err if err
          do_init()
      do_init = ->
        ctx.execute
          # su -l hdfs -c "hdfs namenode -bootstrapStandby -nonInteractive"
          cmd: "su -l hdfs -c \"hdfs namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5
        , (err, executed, stdout) ->
          return next err if err
          next null, if executed then ctx.OK else ctx.PASS
      do_wait()

## Zookeeper JAAS

Secure the Zookeeper connection with JAAS.

    module.exports.push name: 'HDP HDFS NN # Zookeeper JAAS', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_user, hadoop_group, zkfc_password} = ctx.config.hdp
      modified = false
      do_core = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties:
            'ha.zookeeper.auth': "@#{hadoop_conf_dir}/zk-auth.txt"
            'ha.zookeeper.acl': "@#{hadoop_conf_dir}/zk-acl.txt"
          merge: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_content()
      do_content = ->
        ctx.write [
          destination: "#{hadoop_conf_dir}/zk-auth.txt"
          content: "digest:hdfs-zkfcs:#{zkfc_password}"
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o700
        ,
          destination: "#{hadoop_conf_dir}/zk-auth.txt"
          content: "digest:hdfs-zkfcs:#{zkfc_password}"
          uid: hdfs_user.name
          gid: hadoop_group.name
          mode: 0o700
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
        next null, if modified then ctx.OK else ctx.PASS
      do_core()

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

    module.exports.push name: 'HDP HDFS NN # HA Auto Failover', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, active_nn, active_nn_host} = ctx.config.hdp
      zookeepers = ctx.hosts_with_module 'ryba/hadoop/zookeeper'
      modified = false
      do_hdfs = ->
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/hdfs-site.xml"
          properties: 'dfs.ha.automatic-failover.enabled': 'true'
          merge: true
        , (err, configured) ->
          return next err if err
          modified = true if configured
          do_core()
      do_core = ->
        quorum = ctx.config.servers
          .filter( (server) -> zookeepers.indexOf(server.host) isnt -1 )
          .map( (server) -> "#{server.host}:2181" )
          .join ','
        ctx.hconfigure
          destination: "#{hadoop_conf_dir}/core-site.xml"
          properties: 'ha.zookeeper.quorum': quorum
          merge: true
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
            next null, if formated or started then ctx.OK else ctx.PASS
      do_zkfc_standby = ->
        ctx.log "Wait for active NameNode to take leadership"
        ctx.waitForExecution
          # hdfs haadmin -getServiceState hadoop1
          cmd: mkcmd.hdfs ctx, "hdfs haadmin -getServiceState #{active_nn_host.split('.')[0]}"
          code_skipped: 255
        , (err, stdout) ->
          return next err if err
          lifecycle.zkfc_start ctx, (err, started) ->
            next null, if started then ctx.OK else ctx.PASS
      do_hdfs()

## Start

    module.exports.push 'ryba/hadoop/hdfs_nn_start'

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    # module.exports.push name: 'HDP HDFS NN # Test User', timeout: -1, callback: (ctx, next) ->
    #   {test_user, test_password, hadoop_group, security} = ctx.config.hdp
    #   {realm, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_client
    #   modified = false
    #   do_user = ->
    #     if security is 'kerberos'
    #     then do_user_krb5()
    #     else do_user_unix()
    #   do_user_unix = ->
    #     ctx.execute
    #       cmd: "useradd #{test_user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop to test\""
    #       code: 0
    #       code_skipped: 9
    #     , (err, created) ->
    #       return next err if err
    #       modified = true if created
    #       do_run()
    #   do_user_krb5 = ->
    #     ctx.krb5_addprinc
    #       principal: "#{test_user.name}@#{realm}"
    #       password: "#{test_password}"
    #       kadmin_principal: kadmin_principal
    #       kadmin_password: kadmin_password
    #       kadmin_server: admin_server
    #     , (err, created) ->
    #       return next err if err
    #       modified = true if created
    #       do_run()
    #   do_run = ->
    #     # Carefull, this is a dupplicate of
    #     # "HDP HDFS DN # HDFS layout"
    #     ctx.execute
    #       cmd: mkcmd.hdfs ctx, """
    #       if hdfs dfs -ls /user/test 2>/dev/null; then exit 2; fi
    #       hdfs dfs -mkdir /user/#{test_user.name}
    #       hdfs dfs -chown #{test_user.name}:#{hadoop_group.name} /user/#{test_user.name}
    #       hdfs dfs -chmod 755 /user/#{test_user.name}
    #       """
    #       code_skipped: 2
    #     , (err, executed, stdout) ->
    #       modified = true if executed
    #       next err, if modified then ctx.OK else ctx.PASS
    #   do_user()

[qjm]: http://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html
