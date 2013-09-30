
url = require 'url'
hconfigure = require './hadoop/lib/hconfigure'
module.exports = []

module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/krb5_client' #kadmin must be present

module.exports.push module.exports.configure = (ctx) ->
  proxy = require './proxy'
  proxy.configure ctx
  ctx.config.hdp ?= {}
  ctx.config.hdp.format ?= false
  ctx.config.hdp.java_home ?= '/usr/java/default'
  ctx.config.hdp.hadoop_opts ?= 'java.net.preferIPv4Stack': true
  hadoop_opts = "export HADOOP_OPTS=\""
  for k, v of ctx.config.hdp.hadoop_opts
    hadoop_opts += "-D#{k}=#{v} "
  hadoop_opts += "${HADOOP_OPTS}\""
  ctx.config.hdp.hadoop_opts = hadoop_opts
  # Repository
  ctx.config.hdp.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.hdp is 'undefined'
  # see [Meet Minimum System Requirements](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap1-2.html)
  ctx.config.hdp.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/GA/hdp.repo'
  ctx.config.hdp.ambari_repo ?= 'http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.2.5.17/ambari.repo'
  # Define the role
  ctx.config.hdp.namenode ?= false
  ctx.config.hdp.secondary_namenode ?= false
  ctx.config.hdp.jobtraker ?= false
  ctx.config.hdp.tasktraker ?= false
  ctx.config.hdp.datanode ?= false
  ctx.config.hdp.hbase_master ?= false
  ctx.config.hdp.hbase_regionserver ?= false
  ctx.config.hdp.zookeeper ?= false
  ctx.config.hdp.hcatalog_server ?= false
  ctx.config.hdp.oozie ?= false
  ctx.config.hdp.webhcat ?= false
  # Define Users and Groups
  ctx.config.hdp.hdfs_user ?= 'hdfs'
  ctx.config.hdp.mapred_user ?= 'mapred'
  ctx.config.hdp.hive_user ?= 'hive'
  ctx.config.hdp.webhcat_user ?= 'webhcat'
  ctx.config.hdp.oozie_user ?= 'oozie'
  ctx.config.hdp.pig_user ?= 'pig'
  ctx.config.hdp.hadoop_group ?= 'hadoop'
  # Define Directories for Core Hadoop
  ctx.config.hdp.dfs_name_dir ?= ['/hadoop/hdfs/namenode']
  ctx.config.hdp.dfs_data_dir ?= ['/hadoop/hdfs/data']
  ctx.config.hdp.fs_checkpoint_edit_dir ?= ['/hadoop/hdfs/snn'] # Default ${hadoop.tmp.dir}/dfs/namesecondary
  ctx.config.hdp.fs_checkpoint_dir ?= ['/hadoop/hdfs/snn'] # Default ${fs.checkpoint.dir}
  ctx.config.hdp.hdfs_log_dir ?= '/var/log/hadoop/hdfs'
  ctx.config.hdp.hdfs_pid_dir ?= '/var/run/hadoop/hdfs'
  ctx.config.hdp.hdfs_conf_dir ?= '/etc/hadoop/conf'
  ctx.config.hdp.mapreduce_local_dir ?= ['/hadoop/mapred']
  ctx.config.hdp.mapred_log_dir ?= '/var/log/hadoop/mapred'
  ctx.config.hdp.mapred_pid_dir ?= '/var/run/hadoop/mapred'
  # Define Directories for Ecosystem Components
  ctx.config.hdp.pig_conf_dir ?= '/etc/pig/conf'
  ctx.config.hdp.oozie_conf_dir ?= '/var/db/oozie'
  ctx.config.hdp.oozie_data ?= '/var/log/oozie'
  ctx.config.hdp.oozie_log_dir ?= '/var/log/oozie'
  ctx.config.hdp.oozie_pid_dir ?= '/var/run/oozie'
  ctx.config.hdp.oozie_tmp_dir ?= '/var/tmp/oozie'
  ctx.config.hdp.hive_conf_dir ?= '/etc/hive/conf'
  ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
  ctx.config.hdp.hive_pid_dir ?= '/var/run/hive'
  ctx.config.hdp.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
  ctx.config.hdp.webhcat_log_dir ?= '/var/log/webhcat/webhcat'
  ctx.config.hdp.webhcat_pid_dir ?= '/var/run/webhcat'
  ctx.config.hdp.sqoop_conf_dir ?= '/etc/sqoop/conf'
  # Options and configuration
  ctx.config.hdp.namenode_port ?= '50070'
  ctx.config.hdp.core ?= {}
  ctx.config.hdp.hdfs ?= {}
  ctx.config.hdp.hdfs['dfs.datanode.data.dir.perm'] ?= '750'
  ctx.config.hdp.mapred ?= {}
  ctx.config.hdp.mapred['mapreduce.job.counters.max'] ?= 120
  ctx.config.hdp.options ?= {}
  ctx.config.hdp.options['java.net.preferIPv4Stack'] ?= true
  ctx.hconfigure = (options, callback) ->
    options.ssh = ctx.ssh if typeof options.ssh is 'undefined'
    options.log ?= ctx.log
    hconfigure options, callback

###
Repository
----------
Declare the Ambari custom repository.
###
module.exports.push (ctx, next) ->
  {proxy, hdp_repo, ambari_repo} = ctx.config.hdp
  # Is there a repo to download and install
  # return next() unless repo
  @name 'HDP # Repo'
  modified = false
  @timeout -1
  do_hdp = ->
    ctx.log "Download #{hdp_repo} to /etc/yum.repos.d/hdp.repo"
    u = url.parse hdp_repo
    ctx[if u.protocol is 'http:' then 'download' else 'upload']
      source: hdp_repo
      proxy: proxy
      destination: '/etc/yum.repos.d/hdp.repo'
    , (err, downloaded) ->
      return next err if err
      modified = true if downloaded
      do_ambari()
  do_ambari = ->
    ctx.log "Download #{ambari_repo} to /etc/yum.repos.d/ambari.repo"
    u = url.parse ambari_repo
    ctx[if u.protocol is 'http:' then 'download' else 'upload']
      source: ambari_repo
      proxy: proxy
      destination: '/etc/yum.repos.d/ambari.repo'
    , (err, downloaded) ->
      return next err if err
      modified = true if downloaded
      do_end()
  do_end = ->
      return next null, ctx.PASS unless modified
      ctx.log 'Clean up metadata and update'
      ctx.execute
        cmd: "yum clean metadata; yum update -y"
      , (err, executed) ->
        next err, ctx.OK
  do_hdp()

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP # Users & Groups"
  cmds = []
  {hadoop_group} = ctx.config.hdp
  cmds.push "groupadd hadoop"
  cmds.push "useradd hdfs -c \"Used by Hadoop HDFS service\" -r -g #{hadoop_group}" if ctx.config.hdp.namenode or ctx.config.hdp.secondary_namenode or ctx.config.hdp.datanode
  cmds.push "useradd mapred -c \"Used by Hadoop MapReduce service\" -r -g #{hadoop_group}" if ctx.config.hdp.jobtraker or ctx.config.hdp.tasktraker
  cmds.push "useradd hive -c \"Used by Hadoop Hive service\" -r -g #{hadoop_group}"
  cmds.push "useradd pig -c \"Used by Hadoop Pig service\" -r -g #{hadoop_group}"
  cmds.push "useradd hcat -c \"Used by Hadoop HCatalog/WebHCat service\" -r -g #{hadoop_group}" if ctx.config.hdp.hcatalog_server or ctx.config.hdp.webhcat
  cmds.push "useradd oozie -c \"Used by Hadoop Oozie service\" -r -g #{hadoop_group}" if ctx.config.hdp.oozie
  ctx.execute
    cmd: cmds.join '\n'
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Install Common"
  @timeout -1
  ctx.service [
    name: 'hadoop'
  ,
    name: 'hadoop-libhdfs'
  ,
    name: 'hadoop-native'
  ,
    name: 'hadoop-pipes'
  ,
    name: 'hadoop-sbin'
  ,
    name: 'openssl'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Install Compression"
  @timeout -1
  modified = false
  snappy = ->
    ctx.service [
      name: 'snappy'
    ,
      name: 'snappy-devel'
    ], (err, serviced) ->
      return next err if err
      return lzo() unless serviced
      ctx.execute
        cmd: 'ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/Linux-amd64-64/.'
      , (err, executed) ->
        return next err if err
        modified = true
        lzo()
  lzo = ->
    ctx.service [
      name: 'hadoop-lzo'
    ,
      name: 'lzo'
    ,
      name: 'lzo-devel'
    ,
      name: 'hadoop-lzo-native'
    ], (err, serviced) ->
      return next err if err
      modified = true if serviced
      next null, if modified then ctx.OK else ctx.PASS
  snappy()

module.exports.push (ctx, next) ->
  @name "HDP # Directories"
  @timeout -1
  { dfs_name_dir, dfs_data_dir, mapreduce_local_dir, 
    fs_checkpoint_edit_dir, fs_checkpoint_dir
    hdfs_user, mapred_user, hadoop_group,
    hdfs_log_dir, mapred_log_dir, hdfs_pid_dir, mapred_pid_dir} = ctx.config.hdp
  modified = false
  do_namenode = ->
    ctx.log "Create namenode dir: #{dfs_name_dir}"
    ctx.mkdir
      destination: dfs_name_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_secondarynamenode()
  do_secondarynamenode = ->
    ctx.log "Create secondarynamenode dir: #{dfs_name_dir}"
    ctx.mkdir
      destination: dfs_name_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_datanode()
  do_datanode = ->
    ctx.log "Create datanode dir: #{dfs_data_dir}"
    ctx.mkdir
      destination: dfs_data_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '750'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_mapred()
  do_mapred = ->
    ctx.log "Create mapred dir: #{mapreduce_local_dir}"
    ctx.mkdir
      destination: mapreduce_local_dir
      uid: mapred_user
      gid: hadoop_group
      mode: '755'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_checkpoint()
  do_checkpoint = ->
    ctx.log "Create checkpoint dir: #{mapreduce_local_dir}"
    ctx.mkdir [
      destination: fs_checkpoint_edit_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    ,
      destination: fs_checkpoint_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    ], (err, created) ->
      return next err if err
      modified = true if created
      do_log()
  do_log = ->
    ctx.log "Create hdfs and mapred log: #{hdfs_log_dir} and #{mapred_log_dir}"
    ctx.mkdir [
      destination: hdfs_log_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    ,
      destination: mapred_log_dir
      uid: mapred_user
      gid: hadoop_group
      mode: '755'
    ], (err, created) ->
      return next err if err
      modified = true if created
      do_pid()
  do_pid = ->
    ctx.log "Create hdfs and mapred pid: #{hdfs_pid_dir} and #{mapred_pid_dir}"
    ctx.mkdir [
      destination: hdfs_pid_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    ,
      destination: mapred_pid_dir
      uid: mapred_user
      gid: hadoop_group
      mode: '755'
    ], (err, created) ->
      return next err if err
      modified = true if created
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_namenode()

module.exports.push (ctx, next) ->
  @name "HDP # Hadoop OPTS"
  {hdfs_conf_dir} = ctx.config.hdp
  ctx.render
    source: "#{__dirname}/hadoop/resources/hadoop-env.sh"
    destination: "#{hdfs_conf_dir}/hadoop-env.sh"
    context: ctx
    local_source: true
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Hadoop Configuration"
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  ctx.log "Namenode: #{namenode}"
  secondary_namenode = (ctx.config.servers.filter (s) -> s.hdp?.secondary_namenode)[0].host
  ctx.log "Secondary namenode: #{secondary_namenode}"
  jobtraker = (ctx.config.servers.filter (s) -> s.hdp?.jobtraker)[0].host
  slaves = (ctx.config.servers.filter (s) -> s.hdp?.datanode).map (s) -> s.host
  { core, hdfs, mapred, hdfs_conf_dir, 
    fs_checkpoint_edit_dir, fs_checkpoint_dir, 
    dfs_name_dir, dfs_data_dir, 
    mapreduce_local_dir, namenode_port } = ctx.config.hdp
  modified = false
  do_core = ->
    ctx.log 'Configure core-site.xml'
    # NameNode hostname
    core['fs.default.name'] ?= "hdfs://#{namenode}:8020"
    # Determines where on the local filesystem the DFS secondary
    # name node should store the temporary images to merge.
    # If this is a comma-delimited list of directories then the image is
    # replicated in all of the directories for redundancy.
    core['fs.checkpoint.edits.dir'] ?= fs_checkpoint_edit_dir.join ','
    # A comma separated list of paths. Use the list of directories from $FS_CHECKPOINT_DIR. 
    # For example, /grid/hadoop/hdfs/snn,sbr/grid1/hadoop/hdfs/snn,sbr/grid2/hadoop/hdfs/snn
    core['fs.checkpoint.dir'] ?= fs_checkpoint_dir.join ','
    ctx.hconfigure
      destination: "#{hdfs_conf_dir}/core-site.xml"
      properties: core
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_hdfs()
  do_hdfs = ->
    ctx.log 'Configure hdfs-site.xml'
    # Comma separated list of paths. Use the list of directories from $DFS_NAME_DIR.  
    # For example, /grid/hadoop/hdfs/nn,/grid1/hadoop/hdfs/nn.
    hdfs['dfs.name.dir'] ?= dfs_name_dir.join ','
    # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.  
    # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
    hdfs['dfs.data.dir'] ?= dfs_data_dir.join ','
    # NameNode hostname for http access.
    hdfs['dfs.http.address'] ?= "hdfs://#{namenode}:#{namenode_port}"
    # Secondary NameNode hostname
    hdfs['dfs.secondary.http.address'] ?= "hdfs://#{secondary_namenode}:50090"
    # NameNode hostname for https access
    hdfs['dfs.https.address'] ?= "hdfs://#{namenode}:50470"
    ctx.hconfigure
      destination: "#{hdfs_conf_dir}/hdfs-site.xml"
      properties: hdfs
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_mapred()
  do_mapred = ->
    ctx.log 'Configure mapred-site.xml'
    # JobTracker hostname
    mapred['mapred.job.tracker'] ?= "hdfs://#{jobtraker}:8021"
    # JobTracker hostname
    mapred['mapred.job.tracker.http.address'] ?= "hdfs://#{jobtraker}:50030"
    # Comma separated list of paths. Use the list of directories from $MAPREDUCE_LOCAL_DIR
    mapred['mapred.local.dir'] ?= mapreduce_local_dir.join ','
    # Enter your group. Use the value of $HADOOP_GROUP
    mapred['mapreduce.tasktracker.group'] ?= 'hadoop'
    # JobTracker hostname
    mapred['mapreduce.history.server.http.address'] ?= "hdfs://#{jobtraker}:51111"
    ctx.hconfigure
      destination: "#{hdfs_conf_dir}/mapred-site.xml"
      properties: mapred
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_taskcontroller()
  do_taskcontroller = ->
    ctx.log 'Configure taskcontroller.cfg'
    # Note, HDP-1.3.1 official doc is awkward, the example show an xml file.
    # http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm_chap3.html
    ctx.ini
      destination: "#{hdfs_conf_dir}/taskcontroller.cfg"
      merge: true
      content:
        'mapred.local.dir': mapreduce_local_dir.join ','
      backup: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_master()
  do_master = ->
    # Accoring to [Yahoo!](http://developer.yahoo.com/hadoop/tutorial/module7.html):
    # The conf/masters file contains the hostname of the
    # SecondaryNameNode. This should be changed from "localhost"
    # to the fully-qualified domain name of the node to run the
    # SecondaryNameNode service. It does not need to contain
    # the hostname of the JobTracker/NameNode machine; 
    # Also some [interesting info about snn](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/)
    ctx.log 'Configure masters'
    ctx.write
      content: "#{secondary_namenode}"
      destination: "#{hdfs_conf_dir}/masters"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_slaves()
  do_slaves = ->
    ctx.log 'Configure slaves'
    ctx.write
      content: "#{slaves.join '\n'}"
      destination: "#{hdfs_conf_dir}/slaves"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_core()

module.exports.push (ctx, next) ->
  @name 'HDP # Environnmental Variables'
  ctx.write
    destination: '/etc/profile.d/hadoop.sh'
    content: """
    #!/bin/bash
    export HADOOP_HOME=/usr/lib/hadoop
    """
    mode: '644'
  , (err, written) ->
    next null, if written then ctx.OK else ctx.PASS


    










