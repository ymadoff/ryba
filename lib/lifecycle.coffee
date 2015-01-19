
url = require 'url'

###
http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html
###
lifecyle = module.exports =
  jn_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hadoop-hdfs-journalnode status"
      code_skipped: [1, 3]
    , callback
  jn_start: (ctx, callback) ->
    {hdfs, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.jn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "JournalNode start"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start journalnode"
        # cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs start journalnode\""
        cmd: 'service hadoop-hdfs-journalnode start'
        # code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen ctx.config.host, 8485, timeout: 20000, (err) ->
          callback err, started
  jn_stop: (ctx, callback) ->
    {hdfs, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.jn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "JournalNode stop"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop journalnode"
        # cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs stop journalnode\""
        cmd: 'service hadoop-hdfs-journalnode stop'
        # code_skipped: 1
      , callback
  nn_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hadoop-hdfs-namenode status"
      code_skipped: [1, 3]
    , callback
  nn_start: (ctx, callback) ->
    lifecyle.nn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "NameNode start"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode"
        # cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs start namenode\""
        cmd: "service hadoop-hdfs-namenode start"
        code_skipped: [1, 3]
      , callback
  nn_stop: (ctx, callback) ->
    {hdfs, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.nn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "NameNode stop"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop namenode"
        # cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs stop namenode\""
        cmd: 'service hadoop-hdfs-namenode stop'
        # code_skipped: 1
      , callback
  nn_restart: (ctx, callback) ->
    ctx.log "NameNode restart"
    lifecyle.nn_stop ctx, (err) ->
      return callback err if err
      lifecyle.nn_start ctx, callback
  zkfc_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hadoop-hdfs-zkfc status"
      code_skipped: [1, 3]
    , callback
  zkfc_start: (ctx, callback) ->
    {hdfs} = ctx.config.ryba
    lifecyle.zkfc_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "ZKFC start"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start zkfc"
        # cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh start zkfc\""
        cmd: 'service hadoop-hdfs-zkfc start'
        # code_skipped: 1
      , callback
  zkfc_stop: (ctx, callback) ->
    {hdfs} = ctx.config.ryba
    lifecyle.zkfc_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "ZKFC stop"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh stop zkfc"
        # cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh stop zkfc\""
        cmd: 'service hadoop-hdfs-zkfc stop'
        # code_skipped: 1
      , callback
  snn_start: (ctx, callback) ->
    {hdfs, hadoop_conf_dir} = ctx.config.ryba
    ctx.log "SNN start"
    ctx.execute
      # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf start secondarynamenode"
      cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} start secondarynamenode\""
      code_skipped: 1
    , callback
  snn_stop: (ctx, callback) ->
    {hdfs, hadoop_conf_dir} = ctx.config.ryba
    ctx.log "SNN stop"
    ctx.execute
      # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop secondarynamenode"
      cmd: "su -l #{hdfs.user.name} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} stop secondarynamenode\""
      # code_skipped: 1
    , callback
  dn_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hadoop-hdfs-datanode status"
      code_skipped: [1, 3]
    , callback
  dn_start: (ctx, callback) ->
    lifecyle.dn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "DataNode start"
      ctx.execute
        # HADOOP_SECURE_DN_USER=hdfs /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode
        # cmd: "HADOOP_SECURE_DN_USER=hdfs /usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs start datanode"
        cmd: "service hadoop-hdfs-datanode start"
        # code_skipped: 1
      , callback
  dn_stop: (ctx, callback) ->
    lifecyle.dn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "DataNode stop"
      ctx.execute
        # /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode
        # cmd: "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} stop datanode"
        cmd: "service hadoop-hdfs-datanode stop"
        # code_skipped: 1
      , callback
  rm_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hadoop-yarn-resourcemanager status"
      code_skipped: [1, 3]
    , callback
  rm_start: (ctx, callback) ->
    {yarn, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.rm_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "ResourceManager start"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager"
        # cmd: "su -l #{yarn.user.name} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} start resourcemanager\""
        cmd: "service hadoop-yarn-resourcemanager start"
        # code_skipped: 1
      , callback
  rm_stop: (ctx, callback) ->
    {yarn, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.rm_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "ResourceManager stop"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
        # cmd: "su -l #{yarn.user.name} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} stop resourcemanager\""
        cmd: "service hadoop-yarn-resourcemanager stop"
        # code_skipped: 1
      , callback
  nm_status: (ctx, callback) ->
    # {yarn_pid_dir, yarn} = ctx.config.ryba
    # ctx.log "NodeManager status"
    # lifecyle.is_pidfile_running ctx, "#{yarn_pid_dir}/#{yarn_user.name}/yarn-#{yarn_user.name}-nodemanager.pid", (err, running) ->
    #   ctx.log "DataNode status: #{if running then 'RUNNING' else 'STOPPED'}"
    #   callback err, running
    ctx.execute
      cmd: "service hadoop-yarn-nodemanager status"
      code_skipped: [1, 3]
    , callback
  nm_start: (ctx, callback) ->
    {yarn, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.nm_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "NodeManager start"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start nodemanager"
        # cmd: "su -l #{yarn.user.name} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} start nodemanager\""
        cmd: "service hadoop-yarn-nodemanager start"
        # code_skipped: 1
      , callback
  nm_stop: (ctx, callback) ->
    {yarn, hadoop_conf_dir} = ctx.config.ryba
    lifecyle.nm_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "NodeManager stop"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop nodemanager"
        # cmd: "su -l #{yarn.user.name} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} stop nodemanager\""
        cmd: "service hadoop-yarn-nodemanager stop"
        # code_skipped: 1
      , callback
  jhs_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hadoop-mapreduce-historyserver status"
      code_skipped: [1, 3]
    , callback
  jhs_start: (ctx, callback) ->
    lifecyle.jhs_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "JobHistoryServer start"
      ctx.execute
        # su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver"
        # cmd: "su -l #{mapred.user.name} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config #{hadoop_conf_dir} start historyserver\""
        cmd: 'service hadoop-mapreduce-historyserver start'
        # code_skipped: 1
      , callback
  jhs_stop: (ctx, callback) ->
    lifecyle.jhs_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "JobHistoryServer stop"
      ctx.execute
        # su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf stop historyserver"
        # cmd: "su -l #{mapred.user.name} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config #{hadoop_conf_dir} stop historyserver\""
        cmd: 'service hadoop-mapreduce-historyserver stop'
        # code_skipped: 1
      , callback
  hive_metastore_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hive-hcatalog-server status"
      code_skipped: [1, 3]
    , callback
  hive_metastore_start: (ctx, callback) ->
    {metastore} = ctx.config.ryba.hive
    lifecyle.hive_metastore_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Hive Metastore start"
      ctx.execute
        # su -l hive -c 'nohup hive --service metastore >/var/log/hive/hive.out 2>/var/log/hive/hive.log & echo $! >/var/run/hive/metastore.pid'
        cmd: "service hive-hcatalog-server start"
        # code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen metastore.host, metastore.port, timeout: metastore.timeout, (err) ->
          callback err, started
  hive_metastore_stop: (ctx, callback) ->
    lifecyle.hive_metastore_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Hive Metastore stop"
      ctx.execute
        # su -l hive -c "kill `cat /var/run/hive/metastore.pid`"
        cmd: "service hive-hcatalog-server stop"
        # code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  hive_metastore_restart: (ctx, callback) ->
    ctx.log "Hive Metastore restart"
    lifecyle.hive_metastore_stop ctx, (err) ->
      return callback err if err
      lifecyle.hive_metastore_start ctx, callback
  hive_server2_status: (ctx, callback) ->
    ctx.execute
      cmd: "service hive-server2 status"
      code_skipped: [1, 3]
    , callback
  hive_server2_start: (ctx, callback) ->
    {hive_server2} = ctx.config.ryba.hive
    lifecyle.hive_server2_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Hive Server2 start"
      ctx.execute
        # su -l hive -c 'nohup /usr/lib/hive/bin/hiveserver2 >/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log & echo $! >/var/run/hive/server2.pid'
        cmd: 'service hive-server2 start'
        # code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen hive_server2.host, hive_server2.port, timeout: hive_server2.timeout, (err) ->
          callback err, started
  hive_server2_stop: (ctx, callback) ->
    lifecyle.hive_server2_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Hive Server2 stop"
      ctx.execute
        # su -l hive -c "kill `cat /var/run/hive/server2.pid`"
        cmd: 'service hive-server2 stop'
        # code_skipped: 1
      , callback
  hive_server2_restart: (ctx, callback) ->
    ctx.log "Hive Server2 restart"
    lifecyle.hive_server2_stop ctx, (err) ->
      return callback err if err
      lifecyle.hive_server2_start ctx, callback
  # oozie_status: (ctx, callback) ->
  #   ctx.log "Oozie status"
  #   {oozie} = ctx.config.ryba
  #   lifecyle.is_pidfile_running ctx, "#{oozie.pid_dir}/oozie.pid", (err, running) ->
  #     ctx.log "Oozie status: #{if running then 'RUNNING' else 'STOPPED'}"
  #     callback err, running
  # oozie_start: (ctx, callback) ->
  #   {oozie} = ctx.config.ryba
  #   lifecyle.oozie_status ctx, (err, running) ->
  #     return callback err, false if err or running
  #     ctx.log "Oozie start"
  #     ctx.execute
  #       # su -l oozie -c "/usr/lib/oozie/bin/oozied.sh start"
  #       cmd: "su -l #{oozie.user.name} -c \"/usr/lib/oozie/bin/oozied.sh start\""
  #     , callback
  # oozie_stop: (ctx, callback) ->
  #   {oozie} = ctx.config.ryba
  #   lifecyle.oozie_status ctx, (err, running) ->
  #     return callback err, false if err or not running
  #     ctx.log "Oozie stop"
  #     ctx.execute
  #       # su -l oozie -c "/usr/lib/oozie/bin/oozied.sh stop"
  #       cmd: "su -l #{oozie.user.name} -c \"/usr/lib/oozie/bin/oozied.sh stop\""
  #     , callback
  # hbase_master_status: (ctx, callback) ->
  #   ctx.log "HBase Master status"
  #   ctx.execute
  #     cmd: "service hbase-master status"
  #     code_skipped: [1, 3]
  #   , callback
  # hbase_master_start: (ctx, callback) ->
  #   {hbase} = ctx.config.ryba
  #   lifecyle.hbase_master_status ctx, (err, running) ->
  #     return callback err, false if err or running
  #     ctx.log "HBase Master start"
  #     ctx.execute
  #       # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master"
  #       # cmd: "su -l #{hbase.user.name} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase.conf_dir} start master\""
  #       cmd: "service hbase-master start"
  #     , callback
  # hbase_master_stop: (ctx, callback) ->
  #   {hbase} = ctx.config.ryba
  #   lifecyle.hbase_master_status ctx, (err, running) ->
  #     return callback err, false if err or not running
  #     ctx.log "HBase Master stop"
  #     ctx.execute
  #       # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop master"
  #       # cmd: "su -l #{hbase.user.name} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase.conf_dir} stop master\""
  #       cmd: "service hbase-master stop"
  #     , callback
  # hbase_regionserver_status: (ctx, callback) ->
  #   # {hbase} = ctx.config.ryba
  #   ctx.log "HBase RegionServer status"
  #   # lifecyle.is_pidfile_running ctx, "#{hbase_pid_dir}/hbase-#{hbase_user.name}-regionserver.pid", (err, running) ->
  #   #   ctx.log "HBase RegionServer status: #{if running then 'RUNNING' else 'STOPPED'}"
  #   #   callback err, running
  #   ctx.execute
  #     cmd: "service hbase-regionserver status"
  #     code_skipped: [1, 3]
  #   , callback
  # hbase_regionserver_start: (ctx, callback) ->
  #   {hbase} = ctx.config.ryba
  #   lifecyle.hbase_regionserver_status ctx, (err, running) ->
  #     return callback err, false if err or running
  #     ctx.log "HBase RegionServer start"
  #     ctx.execute
  #       # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver"
  #       # cmd: "su -l #{hbase_user.name} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase_conf_dir} start regionserver\""
  #       cmd: 'service hbase-regionserver start'
  #     , callback
  # hbase_regionserver_stop: (ctx, callback) ->
  #   {hbase} = ctx.config.ryba
  #   lifecyle.hbase_regionserver_status ctx, (err, running) ->
  #     return callback err, false if err or not running
  #     ctx.log "HBase RegionServer stop"
  #     ctx.execute
  #       # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
  #       # cmd: "su -l #{hbase_user.name} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase_conf_dir} stop regionserver\""
  #       cmd: 'service hbase-regionserver stop'
  #     , callback
  # webhcat_status: (ctx, callback) ->
  #   {webhcat.pid_dir} = ctx.config.ryba
  #   # lifecyle.is_pidfile_running ctx, "#{webhcat.pid_dir}/webhcat.pid", (err, running) ->
  #   #   ctx.log "WebHCat status: #{if running then 'RUNNING' else 'STOPPED'}"
  #   #   callback err, running
  #   ctx.execute
  #     cmd: "service hive-webhcat-server status"
  #     code_skipped: [1, 3]
  #   , callback
  # webhcat_start: (ctx, callback) ->
  #   lifecyle.webhcat_status ctx, (err, running) ->
  #     return callback err, false if err or running
  #     ctx.log "WebHCat start"
  #     ctx.execute
  #       # su -l hive -c "/usr/lib/hive-hcatalog/sbin/webhcat_server.sh start"
  #       cmd: "service hive-webhcat-server start"
  #     , callback
  # webhcat_stop: (ctx, callback) ->
  #   lifecyle.webhcat_status ctx, (err, running) ->
  #     return callback err, false if err or not running
  #     ctx.log "WebHCat stop"
  #     ctx.execute
  #       # su -l hive -c "/usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop"
  #       cmd: "service hive-webhcat-server stop"
  #     , callback
  hue_status: (ctx, callback) ->
    ctx.log "Hue status"
    # We are not here to check if service is installed, for example this is
    # called when stoping the service and we dont expect an error to be thrown
    # if service isnt yet installed.
    # exit code 1: not installed
    # exit code 3: not started
    ctx.execute
      cmd: "service hue status"
      code_skipped: [1, 3]
    , callback
  hue_start: (ctx, callback) ->
    lifecyle.hue_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Hue start"
      ctx.execute
        cmd: "service hue start"
      , callback
  hue_stop: (ctx, callback) ->
    lifecyle.hue_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Hue stop"
      ctx.execute
        cmd: "service hue stop"
      , callback
  zookeeper_status: (ctx, callback) ->
    # {zookeeper} = ctx.config.ryba
    ctx.log "Zookeeper status"
    # lifecyle.is_pidfile_running ctx, "#{zookeeper.pid_dir}/zookeeper_server.pid", (err, running) ->
    #   ctx.log "Zookeeper status: #{if running then 'RUNNING' else 'STOPPED'}"
    #   callback err, running
    ctx.execute
      cmd: "service zookeeper-server status"
      code_skipped: [1, 3]
    , callback
  zookeeper_start: (ctx, callback) ->
    {zookeeper} = ctx.config.ryba
    lifecyle.zookeeper_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Zookeeper start"
      ctx.execute
        # su -l zookeeper -c "/usr/lib/zookeeper/bin/zkServer.sh start /etc/zookeeper/conf/zoo.cfg"
        # cmd: "su -l #{zookeeper.user.name} -c \"/usr/lib/zookeeper/bin/zkServer.sh start #{zookeeper.conf_dir}/zoo.cfg\""
        cmd: "service zookeeper-server start"
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen ctx.config.host, zookeeper.port, timeout: 2000000, (err) ->
          callback err, started
  zookeeper_stop: (ctx, callback) ->
    {zookeeper} = ctx.config.ryba
    lifecyle.zookeeper_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Zookeeper stop"
      ctx.execute
        # su -l zookeeper -c "/usr/lib/zookeeper/bin/zkServer.sh stop /etc/zookeeper/conf/zoo.cfg"
        # cmd: "su -l #{zookeeper.user.name} -c \"/usr/lib/zookeeper/bin/zkServer.sh stop #{zookeeper.conf_dir}/zoo.cfg\""
        cmd: "service zookeeper-server stop"
      , callback

module.exports.is_pidfile_running = (ctx, path, callback) ->
  ctx.execute
    cmd: """
    if pid=`cat #{path}`; then
      if ps -e -o pid | grep -v grep | grep -w $pid; then exit 0;
    fi; fi; exit 1
    """
    code_skipped: 1
  , (err, started) ->
    callback err, started
