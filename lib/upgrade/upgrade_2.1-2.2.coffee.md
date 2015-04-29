
# Upgrade HDP 2.1 to 2.2

Follow official instruction from [Hortonworks HDP 2.2 Manual Upgrade][upgrade]

    exports = module.exports = (params, config, callback) ->
      params.easy_download
      return callback Error "Missing 'repo' option" unless params.repo?
      # params.repo ?= './resources/repos/hdp-2.2.0.0.local.repo'
      config.params = params
      config.directory = '/var/ryba/upgrade'
      exports.contexts config, (err, contexts) ->
        return callback err if err
        middlewares = [
          'backup'
          'hdfs_fsck'
          'hdfs_namespaces'
          'hdfs_report'
          'hdfs_save'
          'hive'
          'stop'
          'hdfs_check_edits'
          'remove'
          'repo'
          'services'
          'cleanup'
          'hdp_select'
          'install'
          'hdfs_upgrade'
          'hdfs_standby'
          'hdfs_dn'
          'hdfs_validate'
          'hdfs_upgrade_nn_running'
          'hdfs_finalize'
          'dispose'
        ]
        started = !params.start
        each middlewares
        .run (name, next) ->
          started = true if params.start and params.start is name
          return next() unless started
          middleware = exports[name]
          middleware.name = name
          util.print "[#{name}] #{middleware.label}: "
          middleware.handler.call null, config, contexts, (err, changed) ->
            if err
              util.print " ERROR: #{err.message}\n"
              if err.errors
                for err in err.errors
                  util.print "   #{err.message}\n"
            else if changed is false or changed is 0
              util.print " OK"
            else if not changed?
              util.print " SKIPPED"
            else
              util.print " CHANGED"
            util.print '\n'
            next err
        .then (err) ->
          util.print "Disconnecting: "
          exports.disconnect.call null, config, contexts, (err) ->
            if err
              util.print " ERROR: #{err.message}"
            else
              util.print " OK"
            util.print '\n'
            callback err

## SSH

    exports.contexts = (config, next) ->
      contexts = []
      params = merge {}, config.params
      params.end = false
      params.hosts = null
      params.modules = [
        'masson/bootstrap/connection', 'masson/bootstrap/info'
        'masson/bootstrap/mecano', 'masson/bootstrap/log'
      ]
      run params, config
      .on 'context', (context) ->
        contexts.push context
      .on 'error', next
      .on 'end', -> next null, contexts

## Backup

Backup configuration files for each services

    exports.backup = label: 'Backup', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        cmds = [ cmd: "rm -rf #{config.directory}; mkdir -p #{config.directory}"]
        if context.has_any_modules ['ryba/hadoop/core']
          cmds.push cmd: "cp -rp /etc/hadoop/conf/ #{config.directory}/hadoop_conf"
        if context.has_any_modules ['ryba/hbase/master', 'ryba/hbase/regionserver', 'ryba/hbase/client']
          cmds.push cmd: "cp -rp /etc/hbase/conf/ #{config.directory}/hbase_conf"
        if context.has_any_modules ['ryba/hive/hcatalog', 'ryba/hive/server2', 'ryba/hive/client']
          cmds.push cmd: "cp -rp /etc/hive/conf/ #{config.directory}/hive_conf"
          cmds.push cmd: "cp -rp /etc/hive-hcatalog/conf/ #{config.directory}/hcatalog_conf"
        if context.has_any_modules ['ryba/hive/webhcat']
          cmds.push cmd: "cp -rp /etc/hive-webhcat/conf/ #{config.directory}/webhcat_conf"
        if context.has_any_modules ['ryba/tools/pig']
          cmds.push cmd: "cp -rp /etc/pig/conf/ #{config.directory}/pig_conf"
        if context.has_any_modules ['ryba/tools/sqoop']
          cmds.push cmd: "cp -rp /etc/sqoop/conf/ #{config.directory}/sqoop_conf"
        if context.has_any_modules ['ryba/tools/flume']
          cmds.push cmd: "cp -rp /etc/flume/conf/ #{config.directory}/flume_conf"
        if context.has_any_modules ['ryba/tools/mahout']
          cmds.push cmd: "cp -rp /etc/mahout/conf/ #{config.directory}/mahout_conf"
        if context.has_any_modules ['ryba/oozie/server', 'ryba/oozie/client']
          cmds.push cmd: "cp -rp /etc/oozie/conf/ #{config.directory}/oozie_conf"
        if context.has_any_modules ['ryba/hue']
          cmds.push cmd: "cp -rp /etc/hue/conf/ #{config.directory}/hue_conf"
        if context.has_any_modules ['ryba/zookeeper']
          cmds.push cmd: "cp -rp /etc/zookeeper/conf/ #{config.directory}/zookeeper_conf"
        if context.has_any_modules ['ryba/tez']
          cmds.push cmd: "cp -rp /etc/tez/conf/ #{config.directory}/tez_conf"
        if context.has_any_modules ['ryba/falcon']
          cmds.push cmd: "cp -rp /etc/falcon/conf/ #{config.directory}/falcon_conf"
        cmds.forEach (cmd) -> cmd.code = [0, 1]
        context.execute cmds, next
      .then next

## HDFS `fsck`

Run the fsck command as the HDFS Service user and fix any errors. The resulting
file contains a complete block map of the file system.

    exports.hdfs_fsck = label: 'HDFS fsck', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() unless context.config.ryba.active_nn_host is context.config.host
        context.execute
          cmd: mkcmd.hdfs context, """
          hdfs fsck / -files -blocks -locations > #{config.directory}/dfs-old-fsck-1.log
          cat #{config.directory}/dfs-old-fsck-1.log | tail -1 | grep HEALTHY
          """
        , next
      .then next

## HDFS Namespace

Capture the complete namespace of the file system.

    exports.hdfs_namespaces = label: 'HDFS Namespaces', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() unless context.config.ryba.active_nn_host is context.config.host
        context.execute
          cmd: mkcmd.hdfs context, """
          hdfs dfs -ls -R / > #{config.directory}/dfs-old-lsr-1.log
          """
        , next
      .then next

## HDFS Report

Capture the complete namespace of the file system.

    exports.hdfs_report = label: 'HDFS Report', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() unless context.config.ryba.active_nn_host is context.config.host
        context.execute
          cmd: mkcmd.hdfs context, """
          hdfs dfsadmin -report > #{config.directory}/dfs-old-report-1.log
          """
        , next
      .then next

## HDFS Save

Save the namespace.

    exports.hdfs_save = label: 'HDFS Save', handler: (config, contexts, next) ->
      do_save_namespaces = ->
        each contexts
        .run (context, next) ->
          return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
          require('../../hadoop/hdfs_nn').configure context
          return next() unless context.config.ryba.active_nn_host is context.config.host
          context.execute
            cmd: mkcmd.hdfs context, """
            hdfs dfsadmin -safemode enter
            hdfs dfsadmin -saveNamespace
            """
            trap_on_error: true
          , next
        .then (err) ->
          return next err if err
          do_save_dirs()
      do_save_dirs = ->
        each contexts
        .run (context, next) ->
          cmds = []
          if context.has_module 'ryba/hadoop/hdfs_nn'
            require('../../hadoop/hdfs_nn').configure context
            for name_dir, i in context.config.ryba.hdfs.site['dfs.namenode.name.dir'].split ','
              cmds.push cmd: "cp -rp #{name_dir}/current #{config.directory}/hdfs_name_#{i}"
          if context.has_module 'ryba/hadoop/hdfs_jn'
            require('../../hadoop/hdfs_jn').configure context
            for edit_dir, i in context.config.ryba.hdfs.site['dfs.journalnode.edits.dir'].split ','
              cmds.push cmd: "cp -rp #{edit_dir} #{config.directory}/hdfs_edits_#{i}"
          return next() unless cmds.length
          context.execute cmds, (err) ->
            return next err if err
            do_finalize()
      do_finalize = ->
        each contexts
        .run (context, next) ->
          return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
          require('../../hadoop/hdfs_nn').configure context
          return next() unless context.config.ryba.active_nn_host is context.config.host
          context.execute
            cmd: mkcmd.hdfs context, """
            hdfs dfsadmin -finalizeUpgrade
            """
          , next
        .then next
      do_save_namespaces()

## Backup Hive

    exports.hive = label: 'Hive Backup', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hive/server'
        require('../../hive/server').configure context
        {hive} = context.config.ryba
        user = hive.site['javax.jdo.option.ConnectionUserName']
        password = hive.site['javax.jdo.option.ConnectionPassword']
        {engine, db, hostname, port} = parse_jdbc hive.site['javax.jdo.option.ConnectionURL']
        cmd =
          mysql: "mysqldump -u#{user} -p#{password} -h#{hostname} -P#{port} #{db} > #{config.directory}/hive_db.sql"
        return next Error 'Database engine not supported' unless cmd[engine]
        context.execute cmd: cmd[engine], next
      .then next

## Stop Services

    exports.stop = label: 'Stop Services', handler: (config, contexts, next) ->
      services = [
        { name: 'zookeeper-server', module: 'ryba/zookeeper' }
        { name: 'hadoop-hdfs-journalnode', module: 'yba/hadoop/hdfs_jn' }
        { name: 'hadoop-hdfs-zkfc', module: 'ryba/hadoop/hdfs_nn'}
        { name: 'hadoop-hdfs-namenode', module: 'ryba/hadoop/hdfs_nn'}
        { name: 'hadoop-hdfs-secondarynamenode', module: 'ryba/hadoop/hdfs_snn'}
        { name: 'hadoop-hdfs-datanode', module: 'ryba/hadoop/hdfs_dn'}
        { name: 'hadoop-yarn-resourcemanager', module: 'ryba/hadoop/yarn_rm'}
        { name: 'hadoop-yarn-nodemanager', module: 'ryba/hadoop/yarn_nm'}
        { name: 'hadoop-mapreduce-historyserver', module: 'ryba/hadoop/mapred_jhs'}
        { name: 'hive-hcatalog-server', module: 'ryba/hive/server'}
        { name: 'hive-server2', module: 'ryba/hive/server'}
        { name: 'hive-webhcat-server', module: 'ryba/hive/webhcat'}
        { name: 'hbase-regionserver', module: 'ryba/hbase/regionserver'}
        { name: 'hbase-master', module: 'ryba/hbase/master'}
        { name: 'hbase-rest', module: 'ryba/hbase/rest'}
        { cmd: """
          if [ ! -f /var/run/oozie.pid ]; then exit 3; fi
          if ! kill -0 >/dev/null 2>&1 `cat /var/run/oozie.pid`; then exit 3; fi
          su -l oozie -c "/usr/lib/oozie/bin/oozied.sh stop 20 -force"
          """, module: 'ryba/oozie/server'}
        { name: 'nagios', module: 'ryba/nagios'}
        { name: 'hdp-gmetad', module: 'ryba/ganglia/collector'}
        { name: 'hdp-gmond', module: 'ryba/ganglia/monitor'}
      ].reverse()
      each services
      .run (service, next) ->
        each contexts
        .parallel true
        .run (context, next) ->
          return next() unless context.has_any_modules service.module
          cmd = service.cmd or "service #{service.name} stop"
          context.log "Stop service '#{service.name}'"
          context.execute
            cmd: cmd
            code_skipped: [1, 3]
          , next
        .then next
      .then next


      # each contexts
      # .parallel true
      # .run (context, next) ->
      #   cmds = []
      #   if context.has_any_modules 'ryba/zookeeper'
      #     cmds.push cmd: 'service zookeeper-server stop'
      #   if context.has_any_modules 'ryba/hadoop/hdfs_jn'
      #     cmds.push cmd: 'service hadoop-hdfs-journalnode stop'
      #   if context.has_any_modules 'ryba/hadoop/hdfs_nn'
      #     cmds.push cmd: 'service hadoop-hdfs-zkfc stop'
      #     cmds.push cmd: 'service hadoop-hdfs-namenode stop'
      #   if context.has_any_modules 'ryba/hadoop/hdfs_snn'
      #     cmds.push cmd: 'service hadoop-hdfs-secondarynamenode stop'
      #   if context.has_any_modules 'ryba/hadoop/hdfs_dn'
      #     cmds.push cmd: 'service hadoop-hdfs-datanode stop'
      #   if context.has_any_modules 'ryba/hadoop/yarn_rm'
      #     cmds.push cmd: 'service hadoop-yarn-resourcemanager stop'
      #   if context.has_any_modules 'ryba/hadoop/yarn_nm'
      #     cmds.push cmd: 'service hadoop-yarn-nodemanager stop'
      #   if context.has_any_modules 'ryba/hadoop/mapred_jhs'
      #     cmds.push cmd: 'service hadoop-mapreduce-historyserver stop'
      #   if context.has_any_modules 'ryba/hive/server'
      #     cmds.push cmd: 'service hive-hcatalog-server stop'
      #     cmds.push cmd: 'service hive-server2 stop'
      #   if context.has_any_modules 'ryba/hive/webhcat'
      #     cmds.push cmd: 'service hive-webhcat-server stop'
      #   if context.has_any_modules 'ryba/hbase/regionserver'
      #     cmds.push cmd: 'service hbase-regionserver stop'
      #   if context.has_any_modules 'ryba/hbase/master'
      #     cmds.push cmd: 'service hbase-master stop'
      #   if context.has_any_modules 'ryba/hbase/rest'
      #     cmds.push cmd: 'service hbase-rest stop'
      #   if context.has_any_modules 'ryba/oozie/server'
      #     cmds.push cmd: """
      #     if [ ! -f /var/run/oozie.pid ]; then exit 3; fi
      #     if ! kill -0 >/dev/null 2>&1 `cat /var/run/oozie.pid`; then exit 3; fi
      #     su -l oozie -c "/usr/lib/oozie/bin/oozied.sh stop 20 -force"
      #     """
      #   if context.has_any_modules 'ryba/nagios'
      #     cmds.push cmd: 'service nagios stop'
      #   if context.has_any_modules 'ryba/ganglia/collector'
      #     cmds.push cmd: 'service hdp-gmetad stop'
      #   if context.has_any_modules 'ryba/ganglia/monitor'
      #     cmds.push cmd: 'service hdp-gmond stop'
      #   for cmd in cmds then cmd.code_skipped = [1, 3]
      #   context.execute cmds.reverse(), next
      # .then next

## HDFS Check Edits

Save the namespace.

    exports.hdfs_check_edits = label: 'HDFS Check Edits', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() unless context.config.ryba.active_nn_host is context.config.host
        each context.config.ryba.hdfs.site['dfs.namenode.name.dir'].split ','
        .run (name_dir, next) ->
          context.execute
            cmd: """
            ls #{name_dir}/current/edits_inprogress_* | wc -l | grep 0
            """
            code_skipped: 1
          , (err, ready) ->
            return next err if err
            return next() if ready
            context.execute """
            hdfs oev -i /var/hdfs/name/current/edits_inprogress_* -o #{config.directory}/hdfs_edits.out
            cat #{config.directory}/hdfs_edits.out | egrep '<OPCODE>(.*?)</OPCODE>' | egrep -v '<OPCODE>OP_START_LOG_SEGMENT</OPCODE>'
            """
            code_skipped: 1
          , (err, invalid) ->
            return next err if err
            return next() unless invalid
            # If edits.out has transactions other than OP_START_LOG_SEGMENT run the following steps and then verify edit logs are empty.
            # Start the existing version NameNode.
            # Ensure there is a new FS image file.
            # Shut the NameNode down.
            # hdfs dfsadmin – saveNamespace
            context.execute
              cmd: mkcmd.hdfs context, """
              service hadoop-hdfs-namenode start
              service hadoop-hdfs-namenode stop
              hdfs dfsadmin –saveNamespace
              ls #{name_dir}/current/edits_inprogress_* | wc -l | grep 0
              """
            , next
        .then next
      .then next

## Remove Services

Remove your old HDP 2.1 components. This command un-installs the HDP 2.1
components. It leaves the user data, and metadata, but removes your
configurations.

    exports.remove = label: 'Remove Services', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        context.execute
          cmd: """
          yum clean all
          yum erase -y \
            "hadoop*" "webhcat*" "oozie*" "collectd*" "gccxml*" "pig*" \
            "hdfs*" "sqoop*" "zookeeper*" "hbase*" "hive*" "tez*" "storm*" \
            "falcon*" "flume*" "phoenix*" "accumulo*" "mahout*" "hue" \
            "hue-common" "hue-shell" "knox*" "hdp_mon_nagios_addons"
          """
        , next
      .then next

## Repository

Upload the HDP 2.2 repository.

    exports.repo = label: 'Repository', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        context.upload
          source: config.params.repo
          destination: '/etc/yum.repos.d/hdp.repo'
        , (err) ->
          return next err if err
          context.execute
            cmd: "yum clean metadata; yum repolist"
          , next
      .then next

## Services

Re-install the major services.

    exports.services = label: 'Services', handler: (config, contexts, next) ->
      each contexts
      .parallel not config.params.easy_download
      .run (context, next) ->
        services = []
        if context.has_any_modules 'ryba/zookeeper/server'
          services.push name: 'zookeeper-server'
        if context.has_any_modules 'ryba/hadoop/hdfs_jn'
          services.push name: 'hadoop-hdfs-journalnode'
        if context.has_any_modules 'ryba/hadoop/core'
          services.push name: 'hadoop-client'
        if context.has_any_modules 'ryba/hadoop/hdfs_nn'
          services.push name: 'hadoop-hdfs-namenode'
          if context.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
            services.push name: 'hadoop-hdfs-zkfc'
        if context.has_any_modules 'ryba/hadoop/hdfs_snn'
          services.push name: 'hadoop-hdfs-secondarynamenode'
        if context.has_any_modules 'ryba/hadoop/hdfs_dn'
          services.push name: 'hadoop-hdfs-datanode'
        if context.has_any_modules 'ryba/hadoop/yarn_rm'
          services.push name: 'hadoop-yarn-resourcemanager'
        if context.has_any_modules 'ryba/hadoop/yarn_nm'
          services.push name: 'hadoop-yarn-nodemanager'
        if context.has_any_modules 'ryba/hadoop/mapred_jhs'
          services.push name: 'hadoop-mapreduce-historyserver'
        context.service services, next
      .then next

## Cleanup

    exports.cleanup = label: 'Cleanup', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        services = []
        context.execute
          cmd: '''
          rm -rf /var/zookeper
          rm -rf /usr/bin/oozie
          rm -rf /etc/profile.d/hadoop.sh
          rm -rf /usr/lib/pig
          rm -rf /usr/lib/falcon
          rm -rf /usr/lib/hadoop
          rm -rf /usr/lib/hive # MySQL jdbc driver link
          rm -rf /usr/lib/hive-hcatalog
          '''
        , next
      .then next

## HDP Select

Symlink Directories with hdp-select

    exports.hdp_select = label: 'HDP Select', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        context.execute
          cmd: 'hdp-select set all 2.2.0.0-2041'
        , next
      .then next

## HDP Install

Install Zookeeper and HDFS.

    exports.install = label: 'HDP Install', handler: (config, contexts, next) ->
      params = merge {}, config.params
      params.end = false
      params.hosts = null
      params.fast = true
      params.modules = [
        'ryba/zookeeper/client/install'
        'ryba/zookeeper/server/install'
        'ryba/hadoop/core'
        'ryba/hadoop/core_ssl'
        'ryba/hadoop/hdfs_jn/install'
        'ryba/hadoop/hdfs'
        'ryba/hadoop/zkfc/install'
        # 'ryba/hadoop/hdfs_nn/install'
        'ryba/hadoop/hdfs_dn/install'
        # 'ryba/zookeeper/server/start'
        # 'ryba/zookeeper/server/wait'
        # 'ryba/hadoop/zkfc/start'
      ]
      run params, config
      .on 'error', next
      # .on 'end', next
      .on 'end', ->
        each contexts
        .parallel true
        .run (context, next) ->
          context.execute [
            # cmd: '/usr/hdp/2.2.0.0-2041/etc/rc.d/init.d/zookeeper-server start'
            cmd: 'service zookeeper-server start'
            if: context.has_module 'ryba/zookeeper/server'
            code_skipped: 3
          ,
            # cmd: '/usr/hdp/2.2.0.0-2041/etc/rc.d/init.d/hadoop-hdfs-zkfc start'
            cmd: 'service hadoop-hdfs-zkfc start'
            if: context.has_module('ryba/hadoop/zkfc') and context.config.ryba.hdfs.active_nn_host is context.config.host
            code_skipped: 3
          ,
            # cmd: '/usr/hdp/2.2.0.0-2041/etc/rc.d/init.d/hadoop-hdfs-journalnode start'
            cmd: 'service hadoop-hdfs-journalnode start'
            if: context.has_module 'ryba/hadoop/hdfs_jn'
            code_skipped: 3
          ], next
        .then next

## HDFS Upgrade

Replace your configuration after upgrading on all the ZooKeeper nodes.

    exports.hdfs_upgrade = label: 'HDFS Upgrade', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() unless context.config.ryba.active_nn_host is context.config.host
        context.execute
          cmd: "su -l hdfs -c '/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh start namenode -upgrade'"
        , next
      .then next

    exports.hdfs_standby = label: 'HDFS Standby', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() if context.config.ryba.active_nn_host is context.config.host
        context.execute [
          # cmd: mkcmd.hdfs context, 'hdfs namenode -bootstrapStandby -force'
          cmd: """
          su -l hdfs -c 'hdfs namenode -bootstrapStandby -force'
          """
        ,
          cmd: """
          su -l hdfs -c '/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh start namenode'
          # service hadoop-hdfs-namenode start
          """
        ], next
      .then next

    exports.hdfs_dn = label: 'HDFS DataNode', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_dn'
        require('../../hadoop/hdfs_dn').configure context
        context.execute
          cmd: "HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode"
        , next
      .then next

    exports.hdfs_validate = label: 'HDFS Validate', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        cmds = []
        if context.has_module 'ryba/hadoop/hdfs_nn'
          require('../../hadoop/hdfs_nn').configure context
          for name_dir, i in context.config.ryba.hdfs.site['dfs.namenode.name.dir'].split ','
            cmds.push
              cmd: "test -d #{name_dir}/previous"
              if: context.config.ryba.active_nn_host is context.config.host
        if context.has_module 'ryba/hadoop/hdfs_jn'
          require('../../hadoop/hdfs_jn').configure context
          for edit_dir, i in context.config.ryba.hdfs.site['dfs.journalnode.edits.dir'].split ','
            cmds.push cmd: "test -d #{edit_dir}/*/previous"
        context.execute cmds, next
      .then next

    exports.hdfs_upgrade_nn_running = label: 'HDFS Upgrade Enter NN Running', handler: (config, contexts, next) ->
      each contexts
      .parallel true
      .run (context, next) ->
        cmds = []
        if context.has_module 'ryba/hadoop/hdfs_nn'
          cmds.push cmd: "ps -ef | grep -i NameNode"
        context.execute cmds, next
      .then next

    exports.hdfs_finalize = label: 'HDFS Finalize', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        return next() unless context.has_module 'ryba/hadoop/hdfs_nn'
        require('../../hadoop/hdfs_nn').configure context
        return next() unless context.config.ryba.active_nn_host is context.config.host
        context.execute
          cmd: mkcmd.hdfs context, """
          hdfs dfsadmin -safemode wait
          hdfs dfsadmin -finalizeUpgrade
          """
          trap_on_error: true
        , next
      .then next

    exports.dispose = label: 'Dispose', handler: (config, contexts, next) ->
      each contexts
      .run (context, next) ->
        context.execute [
          cmd: "HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop datanode"
          if: context.has_module 'ryba/hadoop/hdfs_dn'
        ,
          cmd: "su -l hdfs -c '/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh stop namenode'"
          if: context.has_module 'ryba/hadoop/hdfs_nn'
        ,
          cmd: 'service zookeeper-server stop'
          if: context.has_module 'ryba/zookeeper/server'
          # code_skipped: 3
        ,
          cmd: 'service hadoop-hdfs-zkfc stop'
          if: context.has_module('ryba/hadoop/zkfc')
          # code_skipped: 3
        ,
          cmd: 'service hadoop-hdfs-journalnode stop'
          if: context.has_module 'ryba/hadoop/hdfs_jn'
        ,
          cmd: 'rm -rf /var/run/hadoop'
        ], next
      .then next

## Disconnect

Close all the remote SSH connections.

    exports.disconnect = (config, contexts, next) ->
      context.emit 'end' for context in contexts
      next()

## Dependencies

    util = require 'util'
    each = require 'each'
    {merge} = require 'mecano/lib/misc'
    run = require 'masson/lib/run'
    mkcmd = require '../mkcmd'
    parse_jdbc = require '../parse_jdbc'

[upgrade]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Upgrade_v22/index.html#Item1.1.2
