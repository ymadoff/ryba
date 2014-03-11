
    fs = require 'fs'
    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    each = require 'each'
    exec = require 'superexec'
    misc = require 'mecano/lib/misc'
    module.exports = []
    module.exports.push 'phyla/hdp/hdfs'
    module.exports.push 'phyla/core/nc'

# HDP HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things 
like the directory tree, file permissions, and the mapping of files to block 
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It 
does not store the data of these files itself. It’s important that this metadata 
(and all changes to it) are safely persisted to stable storage for fault tolerance.

This implementation configure an HA HDFS cluster, using the [Quorum Journal Manager (QJM)](qjm)
feature  to share edit logs between the Active and Standby NameNodes.

## Configuration

The NameNode doesn't define new configuration properties. However, it uses properties
define inside the "phyla/hdp/hdfs" and "phyla/core/nc" modules.

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      require('../core/nc').configure ctx

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

    module.exports.push name: 'HDP HDFS NN # Layout', timeout: -1, callback: (ctx, next) ->
      { dfs_name_dir, hdfs_pid_dir, hdfs_user, hadoop_group } = ctx.config.hdp
      ctx.mkdir [
        destination: dfs_name_dir
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o755
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user}"
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o755
      ], (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

## Kerberos

Create a service principal for this NameNode. The principal is named after 
"nn/#{ctx.config.host}@#{realm}".

    module.exports.push name: 'HDP HDFS NN # Kerberos', callback: (ctx, next) ->
      {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
      ctx.krb5_addprinc 
        principal: "nn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nn.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: kadmin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

## HDFS User

Create the HDFS user principal. This will be the super administrator for the HDFS
filesystem. Note, we do not create a principal with a keytab to allow HDFS login
from multiple sessions with braking an active session.

    module.exports.push name: 'HDP HDFS NN # HDFS User', callback: (ctx, next) ->
      {hdfs_user, hdfs_password} = ctx.config.hdp
      {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
      ctx.krb5_addprinc
        principal: "#{hdfs_user}@#{realm}"
        password: hdfs_password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: kadmin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

# Configure HA

Update "hdfs-site.xml" with HA configuration. The inserted properties are
similar than the ones for a client or slave configuration with the addtionnal
"dfs.namenode.shared.edits.dir" and "dfs.namenode.shared.edits.dir" properties. 

    module.exports.push name: 'HDP HDFS NN # Configure HA', callback: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config} = ctx.config.hdp
      journalnodes = ctx.hosts_with_module 'phyla/hdp/hdfs_jn'
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
          uid: hdfs_user
          gid: hadoop_group
          mode: 0o700
        , (err, created) ->
          return next err if err
          do_upload_keys()
      do_upload_keys = ->
        ctx.upload [
          source: "#{ssh_fencing.private_key}"
          destination: "#{hdfs_home}/.ssh"
          uid: hdfs_user
          gid: hadoop_group
          mode: 0o600
        ,
          source: "#{ssh_fencing.public_key}"
          destination: "#{hdfs_home}/.ssh"
          uid: hdfs_user
          gid: hadoop_group
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
            uid: hdfs_user
            gid: hadoop_group
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

    module.exports.push name: 'HDP HDFS NN # Format', callback: (ctx, next) ->
      {active_nn, dfs_name_dir, hdfs_user, format, nameservice} = ctx.config.hdp
      return next() unless format
      # Shall only be executed on the leader namenode
      return next null, ctx.INAPPLICABLE unless active_nn
      journalnodes = ctx.hosts_with_module 'phyla/hdp/hdfs_jn'
      # all the JournalNodes shall be started
      ctx.waitForConnection journalnodes, 8485, (err) ->
        return next err if err
        ctx.execute
          # yes 'Y' | su -l hdfs -c "hdfs namenode -format -clusterId hadooper"
          cmd: "su -l #{hdfs_user} -c \"hdfs namenode -format -clusterId #{nameservice}\""
          # /hadoop/hdfs/namenode/current/VERSION
          not_if_exists: "#{dfs_name_dir[0]}/current/VERSION"
        , (err, executed) ->
          return next err if err
          return next null, if executed then ctx.OK else ctx.PASS
          lifecycle.nn_start ctx, (err, started) ->
            return next err, ctx.OK

    # module.exports.push name: 'HDP HDFS NN # Upgrade', timeout: -1, callback: (ctx, next) ->
    #   # TODO, we have never tested migration in HA mode
    #   return next null, ctx.INAPPLICABLE
    #   {active_nn, hdfs_log_dir} = ctx.config.hdp
    #   # Shall only be executed on the leader namenode
    #   return next null, ctx.INAPPLICABLE unless active_nn
    #   count = (callback) ->
    #     ctx.execute
    #       cmd: "cat #{hdfs_log_dir}/*/*.log | grep 'upgrade to version' | wc -l"
    #     , (err, executed, stdout) ->
    #       callback err, parseInt(stdout.trim(), 10) or 0
    #   ctx.log 'Dont try to upgrade if namenode is running'
    #   lifecycle.nn_status ctx, (err, started) ->
    #     return next err if err
    #     return next null, ctx.DISABLED if started
    #     ctx.log 'Count how many upgrade msg in log'
    #     count (err, c1) ->
    #       return next err if err
    #       ctx.log 'Start namenode'
    #       lifecycle.nn_start ctx, (err, started) ->
    #         return next err if err
    #         return next null, ctx.PASS if started
    #         ctx.log 'Count again'
    #         count (err, c2) ->
    #           return next err if err
    #           return next null, ctx.PASS if c1 is c2
    #           return next new Error 'Upgrade manually'


## HA Init JournalNodes

This action is disabled, it is only usefull when transitionning from a non HA environment. We
kept it here in case we wish to implement HA (de)activation.

Initialize the JournalNodes with the edits data from the local NameNode edits directories
This is executed from the active NameNode. It wait for 
all the JouralNode servers to be started and is only executed if none of 
the directory named after the nameservice is created on each JournalNode host.

    # module.exports.push name: 'HDP HDFS NN # HA Init JournalNodes', timeout: -1, callback: (ctx, next) ->
    #   {nameservice, active_nn} = ctx.config.hdp
    #   # Shall only be executed on the leader namenode
    #   journalnodes = ctx.hosts_with_module 'phyla/hdp/hdfs_jn'
    #   return next null, ctx.INAPPLICABLE unless active_nn
    #   do_wait = ->
    #     # all the JournalNodes shall be started
    #     options = ctx.config.servers
    #       .filter( (server) -> journalnodes.indexOf(server.host) isnt -1 )
    #       .map( (server) -> host: server.host, port: 8485 )
    #     ctx.waitForConnection options, (err) ->
    #       return next err if err
    #       do_init()
    #   do_init = ->
    #     exists = 0
    #     each(journalnodes)
    #     .on 'item', (journalnode, next) ->
    #       ctx.connect journalnode, (err, ssh) ->
    #         return next err if err
    #         dir = "#{ctx.config.hdp.hdfs_site['dfs.journalnode.edits.dir']}/#{nameservice}"
    #         misc.file.exists ssh, dir, (err, exist) ->
    #           exists++ if exist
    #           next()
    #     .on 'error', (err) ->
    #       next err
    #     .on 'end', ->
    #       return next null, ctx.PASS if exists is journalnodes.length
    #       return next null, ctx.TODO if exists > 0 and exists < journalnodes.length
    #       lifecycle.nn_stop ctx, (err, stopped) ->
    #         return next err if err
    #         ctx.execute
    #           cmd: "su -l hdfs -c \"hdfs namenode -initializeSharedEdits -nonInteractive\""
    #         , (err, executed, stdout) ->
    #           return next err if err
    #           next null, ctx.OK
    #   do_wait()

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other, 
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer 
is only executed on a non active NameNode.

    module.exports.push name: 'HDP HDFS NN # HA Init Standby NameNodes', timeout: -1, callback: (ctx, next) ->
      # Shall only be executed on the leader namenode
      {active_nn, active_nn_host} = ctx.config.hdp
      return next null, ctx.INAPPLICABLE if active_nn
      do_wait = ->
        ctx.waitForConnection active_nn_host, 8020, (err) ->
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

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in 
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby 
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

    module.exports.push name: 'HDP HDFS NN # HA Auto Failover', timeout: -1, callback: (ctx, next) ->
      {hadoop_conf_dir, active_nn, active_nn_host} = ctx.config.hdp
      zookeepers = ctx.hosts_with_module 'phyla/hdp/zookeeper'
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
        ctx.waitForConnection zookeepers, 2181, (err) ->
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
          # TODO: There was a time when fencing wasnt ok the first time,
          # this is probably no longer the case, but we need to test before
          # removing the following command.
          # ctx.execute
          #   # hdfs haadmin -transitionToActive -forcemanual hadoop2
          #   cmd: "yes | hdfs haadmin -transitionToActive -forcemanual #{ctx.config.host}"
          #   if: formated
          # , (err, activated) ->
          #   return next err if err
          #   ctx.log "Was #{ctx.config.host} activated: #{activated}"
          #   # next null, if modified then ctx.OK else ctx.PASS
          #   lifecycle.zkfc_start ctx, (err, started) ->
          #     next null, if formated or started then ctx.OK else ctx.PASS
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

Wait for all JournalNodes to be started before starting this NameNode if it wasn't yet started
during the HDFS format phase.

    module.exports.push name: 'HDP HDFS NN # Start', timeout: -1, callback: (ctx, next) ->
      do_wait = ->
        jns = ctx.hosts_with_module 'phyla/hdp/hdfs_jn'
        # Check if we are HA
        return do_start() if jns.length is 0
        # If so, at least one journalnode must be available
        done = false
        e = each(jns)
        .parallel(true)
        .on 'item', (jn, next) ->
          ctx.waitForConnection jn, 8485, (err) ->
            return if done
            done = true
            e.close() # No item will be emitted after this call
            do_start()
        .on 'error', next
      do_start = ->
        lifecycle.nn_start ctx, (err, started) ->
          next err, if started then ctx.OK else ctx.PASS
      do_wait()

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    module.exports.push name: 'HDP HDFS NN # Test User', timeout: -1, callback: (ctx, next) ->
      {hdfs_user, test_user, test_password, hadoop_group, security} = ctx.config.hdp
      {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
      modified = false
      do_user = ->
        if security is 'kerberos'
        then do_user_krb5()
        else do_user_unix()
      do_user_unix = ->
        ctx.execute
          cmd: "useradd #{test_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop to test\""
          code: 0
          code_skipped: 9
        , (err, created) ->
          return next err if err
          modified = true if created
          do_run()
      do_user_krb5 = ->
        ctx.krb5_addprinc
          principal: "#{test_user}@#{realm}"
          password: "#{test_password}"
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: kadmin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_run()
      do_run = ->
        # Carefull, this is a dupplicate of
        # "HDP HDFS DN # HDFS layout"
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -ls /user/test 2>/dev/null; then exit 1; fi
          hdfs dfs -mkdir /user/test
          hdfs dfs -chown test /user/test
          """
          code_skipped: 1
        , (err, executed, stdout) ->
          modified = true if executed
          next err, if modified then ctx.OK else ctx.PASS
      do_user()

[qjm]: http://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html


