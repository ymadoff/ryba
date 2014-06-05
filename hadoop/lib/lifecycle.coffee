
###
http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html
###
lifecyle = module.exports =
  jn_status: (ctx, callback) ->
    {hdfs_user, hdfs_pid_dir} = ctx.config.hdp
    ctx.log "JournalNode status"
    lifecyle.is_pidfile_running ctx, "#{hdfs_pid_dir}/#{hdfs_user}/hadoop-#{hdfs_user}-journalnode.pid", (err, running) ->
      ctx.log "JournalNode status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  jn_start: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.jn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "JournalNode start"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start journalnode"
        cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs start journalnode\""
        code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen ctx.config.host, 8485, timeout: 20000, (err) ->
          callback err, started
  jn_stop: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.jn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "JournalNode stop"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop journalnode" 
        cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs stop journalnode\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  nn_status: (ctx, callback) ->
    {hdfs_pid_dir} = ctx.config.hdp
    ctx.log "NameNode status"
    lifecyle.is_pidfile_running ctx, "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-namenode.pid", (err, running) ->
      ctx.log "NameNode status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  nn_start: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir, hdfs_namenode_ipc_port, hdfs_namenode_http_port, hdfs_namenode_timeout} = ctx.config.hdp
    lifecyle.nn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "NameNode start"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode"
        cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs start namenode\""
        code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen [
          host: ctx.config.host, port: hdfs_namenode_ipc_port
        ,
          host: ctx.config.host, port: hdfs_namenode_http_port
        ], timeout: hdfs_namenode_timeout, (err) ->
          callback err, started
  nn_stop: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.nn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "NameNode stop"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop namenode"
        cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs stop namenode\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  zkfc_status: (ctx, callback) ->
    {hdfs_user, hdfs_pid_dir} = ctx.config.hdp
    ctx.log "ZKFC status"
    lifecyle.is_pidfile_running ctx, "#{hdfs_pid_dir}/#{hdfs_user}/hadoop-#{hdfs_user}-zkfc.pid", (err, running) ->
      ctx.log "ZKFC status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  zkfc_start: (ctx, callback) ->
    {hdfs_user} = ctx.config.hdp
    lifecyle.zkfc_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "ZKFC start"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start zkfc"
        cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh start zkfc\""
        code_skipped: 1
      , (err, started) ->
        return callback err if err
        callback err, started
  zkfc_stop: (ctx, callback) ->
    {hdfs_user} = ctx.config.hdp
    lifecyle.zkfc_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "ZKFC stop"
      ctx.execute
        # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh stop zkfc"
        cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh stop zkfc\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  snn_start: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    ctx.log "SNN start"
    ctx.execute
      # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf start secondarynamenode"
      cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} start secondarynamenode\""
      code_skipped: 1
    , (err, started) ->
      callback err, started
  snn_stop: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    ctx.log "SNN stop"
    ctx.execute
      # su -l hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop secondarynamenode"
      cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} stop secondarynamenode\""
      code_skipped: 1
    , (err, stopped) ->
      callback err, stopped
  dn_status: (ctx, callback) ->
    {hdfs_pid_dir} = ctx.config.hdp
    ctx.log "DataNode status"
    lifecyle.is_pidfile_running ctx, "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-datanode.pid", (err, running) ->
      ctx.log "DataNode status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  dn_start: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.dn_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "DataNode start"
      ctx.execute
        # HADOOP_SECURE_DN_USER=hdfs /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode
        cmd: "HADOOP_SECURE_DN_USER=hdfs /usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} --script hdfs start datanode"
        code_skipped: 1
      , (err, started) ->
        callback err, started
  dn_stop: (ctx, callback) ->
    {hdfs_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.dn_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "DataNode stop"
      ctx.execute
        # /usr/lib/hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode
        cmd: "/usr/lib/hadoop/sbin/hadoop-daemon.sh --config #{hadoop_conf_dir} stop datanode"
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  rm_status: (ctx, callback) ->
    {yarn_pid_dir, yarn_user} = ctx.config.hdp
    ctx.log "ResourceManager status"
    lifecyle.is_pidfile_running ctx, "#{yarn_pid_dir}/#{yarn_user}/yarn-#{yarn_user}-resourcemanager.pid", (err, running) ->
      ctx.log "DataNode status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  rm_start: (ctx, callback) ->
    {yarn_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.rm_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "ResourceManager start"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager"
        cmd: "su -l #{yarn_user} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} start resourcemanager\""
        code_skipped: 1
      , (err, started) ->
        callback err, started
  rm_stop: (ctx, callback) ->
    {yarn_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.rm_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "ResourceManager stop"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
        cmd: "su -l #{yarn_user} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} stop resourcemanager\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  nm_status: (ctx, callback) ->
    {yarn_pid_dir, yarn_user} = ctx.config.hdp
    ctx.log "NodeManager status"
    lifecyle.is_pidfile_running ctx, "#{yarn_pid_dir}/#{yarn_user}/yarn-#{yarn_user}-nodemanager.pid", (err, running) ->
      ctx.log "DataNode status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  nm_start: (ctx, callback) ->
    {yarn_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.nm_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "NodeManager start"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start nodemanager"
        cmd: "su -l #{yarn_user} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} start nodemanager\""
        code_skipped: 1
      , (err, started) ->
        callback err, started
  nm_stop: (ctx, callback) ->
    {yarn_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.nm_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "NodeManager stop"
      ctx.execute
        # su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop nodemanager"
        cmd: "su -l #{yarn_user} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config #{hadoop_conf_dir} stop nodemanager\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  jhs_status: (ctx, callback) ->
    {mapred_pid_dir, mapred_user} = ctx.config.hdp
    ctx.log "JobHistoryServer status"
    lifecyle.is_pidfile_running ctx, "#{mapred_pid_dir}/#{mapred_user}/mapred-#{mapred_user}-historyserver.pid", (err, running) ->
      ctx.log "JobHistoryServer status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  jhs_start: (ctx, callback) ->
    {mapred_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.jhs_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "JobHistoryServer start"
      ctx.execute
        # su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver"
        cmd: "su -l #{mapred_user} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config #{hadoop_conf_dir} start historyserver\""
        code_skipped: 1
      , (err, started) ->
        callback err, started
  jhs_stop: (ctx, callback) ->
    {mapred_user, hadoop_conf_dir} = ctx.config.hdp
    lifecyle.jhs_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "JobHistoryServer stop"
      ctx.execute
        # su -l mapred -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf stop historyserver"
        cmd: "su -l #{mapred_user} -c \"export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec/ && /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config #{hadoop_conf_dir} stop historyserver\""
        code_skipped: 1
      , (err, started) ->
        callback err, started
  hive_metastore_status: (ctx, callback) ->
    # {hive_metastore_pid} = ctx.config.hdp
    ctx.log "Hive Metastore status"
    lifecyle.is_pidfile_running ctx, "/var/run/hive/metastore.pid", (err, running) ->
      ctx.log "Hive Metastore status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  hive_metastore_start: (ctx, callback) ->
    {hive_user, hive_log_dir, hive_pid_dir, hive_metastore_host, hive_metastore_port, hive_metastore_timeout} = ctx.config.hdp
    lifecyle.hive_metastore_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Hive Metastore start"
      ctx.execute
        # su -l hive -c 'nohup hive --service metastore >/var/log/hive/hive.out 2>/var/log/hive/hive.log & echo $! >/var/run/hive/metastore.pid'
        cmd: "su -l #{hive_user.name} -c 'nohup hive --service metastore >#{hive_log_dir}/hive.out 2>#{hive_log_dir}/hive.log & echo $! > /var/run/hive/metastore.pid'"
        code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen hive_metastore_host, hive_metastore_port, timeout: hive_metastore_timeout, (err) ->
          callback err, started
  hive_metastore_stop: (ctx, callback) ->
    {hive_user, hive_pid_dir} = ctx.config.hdp
    lifecyle.hive_metastore_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Hive Metastore stop"
      ctx.execute
        # su -l hive -c "kill `cat /var/run/hive/metastore.pid`"
        cmd: "su -l #{hive_user.name} -c \"kill `cat #{hive_pid_dir}/metastore.pid`\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  hive_metastore_restart: (ctx, callback) ->
    ctx.log "Hive Metastore restart"
    lifecyle.hive_metastore_stop ctx, (err) ->
      return callback err if err
      lifecyle.hive_metastore_start ctx, callback
  hive_server2_status: (ctx, callback) ->
    ctx.log "Hive Server2 status"
    lifecyle.is_pidfile_running ctx, "/var/run/hive/server2.pid", (err, running) ->
      ctx.log "Hive Server2 status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  hive_server2_start: (ctx, callback) ->
    {hive_user, hive_log_dir, hive_pid_dir, hive_server2_host, hive_server2_port, hive_server2_timeout} = ctx.config.hdp
    lifecyle.hive_server2_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Hive Server2 start"
      ctx.execute
        # su -l hive -c 'nohup /usr/lib/hive/bin/hiveserver2 >/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log & echo $! >/var/run/hive/server2.pid'
        cmd: "su -l #{hive_user.name} -c 'nohup /usr/lib/hive/bin/hiveserver2 >#{hive_log_dir}/hiveserver2.out 2>#{hive_log_dir}/hiveserver2.log & echo $! > /var/run/hive/server2.pid'"
        code_skipped: 1
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen hive_server2_host, hive_server2_port, timeout: hive_server2_timeout, (err) ->
          callback err, started
  hive_server2_stop: (ctx, callback) ->
    {hive_user, hive_pid_dir} = ctx.config.hdp
    lifecyle.hive_server2_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Hive Server2 stop"
      ctx.execute
        # su -l hive -c "kill `cat /var/run/hive/server2.pid`"
        cmd: "su -l #{hive_user.name} -c \"kill `cat #{hive_pid_dir}/server2.pid`\""
        code_skipped: 1
      , (err, started) ->
        callback err, started
  hive_server2_restart: (ctx, callback) ->
    ctx.log "Hive Server2 restart"
    lifecyle.hive_server2_stop ctx, (err) ->
      return callback err if err
      lifecyle.hive_server2_start ctx, callback
  oozie_status: (ctx, callback) ->
    ctx.log "Oozie status"
    {oozie_pid_dir} = ctx.config.hdp
    lifecyle.is_pidfile_running ctx, "#{oozie_pid_dir}/oozie.pid", (err, running) ->
      ctx.log "Oozie status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  oozie_start: (ctx, callback) ->
    {oozie_user} = ctx.config.hdp
    lifecyle.oozie_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Oozie start"
      ctx.execute
        # su -l oozie -c "/usr/lib/oozie/bin/oozied.sh start"
        cmd: "su -l #{oozie_user.name} -c \"/usr/lib/oozie/bin/oozied.sh start\""
        code_skipped: 1
      , (err, started) ->
        callback err, started
  oozie_stop: (ctx, callback) ->
    {oozie_user} = ctx.config.hdp
    lifecyle.oozie_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Oozie stop"
      ctx.execute
        # su -l oozie -c "/usr/lib/oozie/bin/oozied.sh stop"
        cmd: "su -l #{oozie_user.name} -c \"/usr/lib/oozie/bin/oozied.sh stop\""
        code_skipped: 1
      , (err, stopped) ->
        callback err, stopped
  zookeeper_status: (ctx, callback) ->
    {zookeeper_pid_dir} = ctx.config.hdp
    ctx.log "Zookeeper status"
    {oozie_pid_dir} = ctx.config.hdp
    lifecyle.is_pidfile_running ctx, "#{zookeeper_pid_dir}/zookeeper_server.pid", (err, running) ->
      ctx.log "Zookeeper status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  zookeeper_start: (ctx, callback) ->
    {zookeeper_user, zookeeper_conf_dir, zookeeper_port} = ctx.config.hdp
    lifecyle.zookeeper_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Zookeeper start"
      ctx.execute
        # su -l zookeeper -c "/usr/lib/zookeeper/bin/zkServer.sh start /etc/zookeeper/conf/zoo.cfg"
        cmd: "su -l #{zookeeper_user} -c \"/usr/lib/zookeeper/bin/zkServer.sh start #{zookeeper_conf_dir}/zoo.cfg\""
      , (err, started) ->
        return callback err if err
        ctx.waitIsOpen ctx.config.host, zookeeper_port, timeout: 2000000, (err) ->
          callback err, started
  zookeeper_stop: (ctx, callback) ->
    {zookeeper_user, zookeeper_conf_dir} = ctx.config.hdp
    lifecyle.zookeeper_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Zookeeper stop"
      ctx.execute
        # su -l zookeeper -c "/usr/lib/zookeeper/bin/zkServer.sh stop /etc/zookeeper/conf/zoo.cfg"
        cmd: "su -l #{zookeeper_user} -c \"/usr/lib/zookeeper/bin/zkServer.sh stop #{zookeeper_conf_dir}/zoo.cfg\""
      , (err, stopped) ->
        callback err, stopped
  hbase_master_status: (ctx, callback) ->
    {hbase_pid_dir, hbase_user} = ctx.config.hdp
    ctx.log "HBase Master status"
    {oozie_pid_dir} = ctx.config.hdp
    lifecyle.is_pidfile_running ctx, "#{hbase_pid_dir}/hbase-#{hbase_user}-master.pid", (err, running) ->
      ctx.log "HBase Master status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  hbase_master_start: (ctx, callback) ->
    {hbase_user, hbase_conf_dir} = ctx.config.hdp
    lifecyle.hbase_master_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "HBase Master start"
      ctx.execute
        # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master"
        cmd: "su -l #{hbase_user} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase_conf_dir} start master\""
      , (err, stopped) ->
        callback err, stopped
  hbase_master_stop: (ctx, callback) ->
    {hbase_user, hbase_conf_dir} = ctx.config.hdp
    lifecyle.hbase_master_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "HBase Master stop"
      ctx.execute
        # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop master"
        cmd: "su -l #{hbase_user} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase_conf_dir} stop master\""
      , (err, stopped) ->
        callback err, stopped
  hbase_regionserver_status: (ctx, callback) ->
    {hbase_pid_dir, hbase_user} = ctx.config.hdp
    ctx.log "HBase RegionServer status"
    {oozie_pid_dir} = ctx.config.hdp
    lifecyle.is_pidfile_running ctx, "#{hbase_pid_dir}/hbase-#{hbase_user}-regionserver.pid", (err, running) ->
      ctx.log "HBase RegionServer status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  hbase_regionserver_start: (ctx, callback) ->
    {hbase_user, hbase_conf_dir} = ctx.config.hdp
    lifecyle.hbase_regionserver_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "HBase RegionServer start"
      ctx.execute
        # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver"
        cmd: "su -l #{hbase_user} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase_conf_dir} start regionserver\""
      , (err, started) ->
        callback err, started
  hbase_regionserver_stop: (ctx, callback) ->
    {hbase_user, hbase_conf_dir} = ctx.config.hdp
    lifecyle.hbase_regionserver_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "HBase RegionServer stop"
      ctx.execute
        # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
        cmd: "su -l #{hbase_user} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config #{hbase_conf_dir} stop regionserver\""
      , (err, stopped) ->
        callback err, stopped
  webhcat_status: (ctx, callback) ->
    {webhcat_pid_dir} = ctx.config.hdp
    ctx.log "WebHCat status"
    lifecyle.is_pidfile_running ctx, "#{webhcat_pid_dir}/webhcat.pid", (err, running) ->
      ctx.log "WebHCat status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  webhcat_start: (ctx, callback) ->
    {webhcat_user, webhcat_conf_dir} = ctx.config.hdp
    lifecyle.webhcat_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "WebHCat start"
      ctx.execute
        # # su -l hcat -c "export WEBHCAT_CONF_DIR=/etc/hcatalog/conf/webhcat; /usr/lib/hive-hcatalog/sbin/webhcat_server.sh start"
        # cmd: "su -l #{webhcat_user.name} -c \"export WEBHCAT_CONF_DIR=#{webhcat_conf_dir}; /usr/lib/hive-hcatalog/sbin/webhcat_server.sh start\""
        # su -l hcat -c "/usr/lib/hive-hcatalog/sbin/webhcat_server.sh start"
        cmd: "su -l #{webhcat_user.name} -c \"/usr/lib/hive-hcatalog/sbin/webhcat_server.sh start\""
      , (err, started) ->
        callback err, true
  webhcat_stop: (ctx, callback) ->
    {webhcat_user, webhcat_conf_dir} = ctx.config.hdp
    lifecyle.webhcat_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "WebHCat stop"
      ctx.execute
        # # su -l hcat -c "export WEBHCAT_CONF_DIR=/etc/hcatalog/conf/webhcat; /usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop"
        # cmd: "su -l #{webhcat_user.name} -c \"export WEBHCAT_CONF_DIR=#{webhcat_conf_dir}; /usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop\""
        # su -l hcat -c "/usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop"
        cmd: "su -l #{webhcat_user.name} -c \"/usr/lib/hive-hcatalog/sbin/webhcat_server.sh stop\""
      , (err, stopped) ->
        callback err, stopped
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
    , (err, running) ->
      ctx.log "Hue status: #{if running then 'RUNNING' else 'STOPED'}"
      callback err, running
  hue_start: (ctx, callback) ->
    lifecyle.hue_status ctx, (err, running) ->
      return callback err, false if err or running
      ctx.log "Hue start"
      ctx.execute
        cmd: "service hue start"
      , (err, stopped) ->
        callback err, stopped
  hue_stop: (ctx, callback) ->
    lifecyle.hue_status ctx, (err, running) ->
      return callback err, false if err or not running
      ctx.log "Hue stop"
      ctx.execute
        cmd: "service hue stop"
      , (err, stopped) ->
        callback err, stopped

module.exports.is_pidfile_running = (ctx, path, callback) ->
  ctx.execute
    cmd: """
    if pid=`cat #{path}`; then
      if ps -e -o pid | grep -v grep | grep -w $pid; then exit 0;
    fi; fi; exit 1
    """
    # cmd: """
    # if pid=`cat #{path}`; then
    #   if ps cax | grep -v grep | grep $pid; then exit 0; else
    #     rm -f #{path}
    # fi; fi; exit 1
    # """
    code_skipped: 1
  , (err, started) ->
    callback err, started









