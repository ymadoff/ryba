
url = require 'url'
hconfigure = require './hadoop/lib/hconfigure'
module.exports = []

module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/krb5_client' #kadmin must be present

###
Note about upgrade from 1.3.x to 2.x, once we install 
the new repo, yum update failed. We should first remove 
some package, here's how: `yum remove hadoop-native hadoop-pipes hadoop-sbin`.
###
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
  ctx.config.hdp.hdp_repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.0.5.0/hdp.repo'
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
  ctx.config.hdp.yarn_user ?= 'yarn'
  ctx.config.hdp.mapred_user ?= 'mapred'
  ctx.config.hdp.webhcat_user ?= 'webhcat'
  ctx.config.hdp.oozie_user ?= 'oozie'
  ctx.config.hdp.pig_user ?= 'pig'
  ctx.config.hdp.hadoop_group ?= 'hadoop'
  # Define Directories for Core Hadoop
  ctx.config.hdp.dfs_name_dir ?= ['/hadoop/hdfs/namenode']
  ctx.config.hdp.dfs_data_dir ?= ['/hadoop/hdfs/data']
  # ctx.config.hdp.fs_checkpoint_edit_dir ?= ['/hadoop/hdfs/snn'] # Default ${hadoop.tmp.dir}/dfs/namesecondary
  ctx.config.hdp.fs_checkpoint_dir ?= ['/hadoop/hdfs/snn'] # Default ${fs.checkpoint.dir}
  ctx.config.hdp.hdfs_log_dir ?= '/var/log/hadoop/hdfs'
  ctx.config.hdp.hdfs_pid_dir ?= '/var/run/hadoop/hdfs'
  ctx.config.hdp.hadoop_conf_dir ?= '/etc/hadoop/conf'
  ctx.config.hdp.yarn_local_dir ?= ['/hadoop/yarn']
  ctx.config.hdp.yarn_log_dir ?= '/var/log/hadoop/yarn'
  ctx.config.hdp.yarn_local_log_dir ?= ['/hadoop/yarn/logs']
  ctx.config.hdp.yarn_pid_dir ?= '/var/run/hadoop/yarn'
  # ctx.config.hdp.mapreduce_local_dir ?= ['/hadoop/mapred']
  ctx.config.hdp.mapred_log_dir ?= '/var/log/hadoop/mapred'
  ctx.config.hdp.mapred_pid_dir ?= '/var/run/hadoop/mapred'
  # Define Directories for Ecosystem Components
  ctx.config.hdp.pig_conf_dir ?= '/etc/pig/conf'
  ctx.config.hdp.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
  ctx.config.hdp.webhcat_log_dir ?= '/var/log/webhcat/webhcat'
  ctx.config.hdp.webhcat_pid_dir ?= '/var/run/webhcat'
  ctx.config.hdp.sqoop_conf_dir ?= '/etc/sqoop/conf'
  # Options and configuration
  ctx.config.hdp.nn_port ?= '50070'
  ctx.config.hdp.snn_port ?= '50090'
  ctx.config.hdp.core ?= {}
  ctx.config.hdp.hdfs ?= {}
  ctx.config.hdp.hdfs['dfs.datanode.data.dir.perm'] ?= '750'
  ctx.config.hdp.yarn ?= {}
  ctx.config.hdp.mapred ?= {}
  ctx.config.hdp.mapred['mapreduce.job.counters.max'] ?= 120
  # http://developer.yahoo.com/hadoop/tutorial/module7.html
  # 1/2 * (cores/node) to 2 * (cores/node)
  ctx.config.hdp.mapred['mapred.tasktracker.map.tasks.maximum'] ?= ctx.config.hdp.dfs_data_dir.length
  ctx.config.hdp.mapred['mapred.tasktracker.reduce.tasks.maximum'] ?= Math.ceil(ctx.config.hdp.dfs_data_dir.length / 2)
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
  cmds.push "useradd hdfs -c \"Used by Hadoop HDFS service\" -r -M -g #{hadoop_group}" if ctx.config.hdp.namenode or ctx.config.hdp.secondary_namenode or ctx.config.hdp.datanode
  cmds.push "useradd yarn -c \"Used by Hadoop YARN service\" -r -M -g #{hadoop_group}" if ctx.config.hdp.jobtraker or ctx.config.hdp.tasktraker
  cmds.push "useradd mapred -c \"Used by Hadoop MapReduce service\" -r -M -g #{hadoop_group}" if ctx.config.hdp.jobtraker or ctx.config.hdp.tasktraker
  cmds.push "useradd hive -c \"Used by Hadoop Hive service\" -r -M -g #{hadoop_group}"
  cmds.push "useradd pig -c \"Used by Hadoop Pig service\" -r -M -g #{hadoop_group}"
  cmds.push "useradd hcat -c \"Used by Hadoop HCatalog/WebHCat service\" -r -M -g #{hadoop_group}" if ctx.config.hdp.hcatalog_server or ctx.config.hdp.webhcat
  cmds.push "useradd oozie -c \"Used by Hadoop Oozie service\" -r -M -g #{hadoop_group}" if ctx.config.hdp.oozie
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
    name: 'hadoop-hdfs'
  ,
    name: 'hadoop-libhdfs'
  ,
    name: 'hadoop-yarn'
  ,
    name: 'hadoop-mapreduce'
  ,
    name: 'hadoop-client'
  ,
    name: 'openssl'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Directories"
  @timeout -1
  { dfs_name_dir, dfs_data_dir, yarn_local_dir, yarn_user, mapred_user, #mapreduce_local_dir, 
    fs_checkpoint_dir, #fs_checkpoint_edit_dir, 
    yarn_log_dir, yarn_local_log_dir, yarn_pid_dir,
    hdfs_user, hadoop_group,
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
      do_yarn()
  do_yarn = ->
    ctx.log "Create yarn dirs: #{yarn_local_dir}"
    ctx.mkdir
      destination: yarn_local_dir
      uid: yarn_user
      gid: hadoop_group
      mode: '755'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_yarn_local_log()
  do_yarn_local_log = ->
    ctx.log "Create yarn dirs: #{yarn_local_dir}"
    ctx.mkdir
      destination: yarn_local_log_dir
      uid: yarn_user
      gid: hadoop_group
      mode: '755'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_checkpoint()
  # do_mapred = ->
  #   ctx.log "Create mapred dir: #{mapreduce_local_dir}"
  #   ctx.mkdir
  #     destination: mapreduce_local_dir
  #     uid: mapred_user
  #     gid: hadoop_group
  #     mode: '755'
  #   , (err, created) ->
  #     return next err if err
  #     modified = true if created
  #     do_checkpoint()
  do_checkpoint = ->
    ctx.log "Create checkpoint dir: #{fs_checkpoint_dir}" # #{fs_checkpoint_edit_dir} and
    ctx.mkdir
      destination: fs_checkpoint_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_log()
  do_log = ->
    ctx.log "Create hdfs and mapred log: #{hdfs_log_dir}, #{yarn_log_dir} and #{mapred_log_dir}"
    ctx.mkdir [
      destination: hdfs_log_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    ,
      destination: yarn_log_dir
      uid: yarn_user
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
    ctx.log "Create hdfs and mapred pid: #{hdfs_pid_dir}, #{yarn_pid_dir} and #{mapred_pid_dir}"
    ctx.mkdir [
      destination: hdfs_pid_dir
      uid: hdfs_user
      gid: hadoop_group
      mode: '755'
    ,
      destination: yarn_pid_dir
      uid: mapred_user
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
  {hadoop_conf_dir} = ctx.config.hdp
  # For now, only "hadoop_opts" config property is used
  # Todo: 
  # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.5.0/bk_installing_manually_book/content/rpm_chap3.html
  # Change the value of the -XX:MaxnewSize parameter to 1/8th the value of the maximum heap size (-Xmx) parameter.
  ctx.render
    source: "#{__dirname}/hdp/core_hadoop/hadoop-env.sh"
    destination: "#{hadoop_conf_dir}/hadoop-env.sh"
    context: ctx
    local_source: true
    uid: 'hdfs'
    gid: 'hadoop'
    mode: '755'
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Yarn OPTS"
  {hadoop_conf_dir} = ctx.config.hdp
  # For now, only "hadoop_opts" config property is used
  # Todo: 
  # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.5.0/bk_installing_manually_book/content/rpm_chap3.html
  # Change the value of the -XX:MaxnewSize parameter to 1/8th the value of the maximum heap size (-Xmx) parameter.
  ctx.render
    source: "#{__dirname}/hdp/core_hadoop/yarn-env.sh"
    destination: "#{hadoop_conf_dir}/yarn-env.sh"
    context: ctx
    local_source: true
    uid: 'yarn'
    gid: 'hadoop'
    mode: '755'
  , (err, rendered) ->
    next err, if rendered then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP # Hadoop Configuration"
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  ctx.log "Namenode: #{namenode}"
  secondary_namenode = (ctx.config.servers.filter (s) -> s.hdp?.secondary_namenode)[0].host
  ctx.log "Secondary namenode: #{secondary_namenode}"
  resourcemanager = (ctx.config.servers.filter (s) -> s.hdp?.resourcemanager)[0].host
  ctx.log "Resource manager: #{resourcemanager}"
  jobhistoryserver = (ctx.config.servers.filter (s) -> s.hdp?.jobhistoryserver)[0].host
  ctx.log "Job History Server: #{jobhistoryserver}"
  jobtraker = (ctx.config.servers.filter (s) -> s.hdp?.jobtraker)[0].host
  slaves = (ctx.config.servers.filter (s) -> s.hdp?.datanode).map (s) -> s.host
  { core, hdfs, yarn, mapred,
    hadoop_conf_dir, fs_checkpoint_dir, # fs_checkpoint_edit_dir,
    dfs_name_dir, dfs_data_dir, 
    yarn_local_dir, nn_port, snn_port } = ctx.config.hdp #mapreduce_local_dir, 
  modified = false
  do_core = ->
    ctx.log 'Configure core-site.xml'
    # NameNode hostname
    core['fs.defaultFS'] ?= "hdfs://#{namenode}:8020"
    console.log core
    # Determines where on the local filesystem the DFS secondary
    # name node should store the temporary images to merge.
    # If this is a comma-delimited list of directories then the image is
    # replicated in all of the directories for redundancy.
    # core['fs.checkpoint.edits.dir'] ?= fs_checkpoint_edit_dir.join ','
    # A comma separated list of paths. Use the list of directories from $FS_CHECKPOINT_DIR. 
    # For example, /grid/hadoop/hdfs/snn,sbr/grid1/hadoop/hdfs/snn,sbr/grid2/hadoop/hdfs/snn
    # core['fs.checkpoint.dir'] ?= fs_checkpoint_dir.join ','
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/core-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/core-site.xml"
      local_default: true
      properties: core
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_hdfs()
  do_hdfs = ->
    ctx.log 'Configure hdfs-site.xml'
    # Comma separated list of paths. Use the list of directories from $DFS_NAME_DIR.  
    # For example, /grid/hadoop/hdfs/nn,/grid1/hadoop/hdfs/nn.
    hdfs['dfs.namenode.name.dir'] ?= dfs_name_dir.join ','
    # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.  
    # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
    hdfs['dfs.datanode.data.dir'] ?= dfs_data_dir.join ','
    # NameNode hostname for http access.
    hdfs['dfs.namenode.http-address'] ?= "hdfs://#{namenode}:#{nn_port}"
    # Secondary NameNode hostname
    hdfs['dfs.namenode.secondary.http-address'] ?= "hdfs://#{secondary_namenode}:#{snn_port}"
    # NameNode hostname for https access
    hdfs['dfs.https.address'] ?= "hdfs://#{namenode}:50470"
    hdfs['dfs.namenode.checkpoint.dir'] ?= fs_checkpoint_dir.join ','
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/hdfs-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/hdfs-site.xml"
      local_default: true
      properties: hdfs
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_yarn()
  do_yarn = ->
    ctx.log 'Configure yarn-site.xml'
    # Enter your ResourceManager hostname.
    yarn['yarn.resourcemanager.resource-tracker.address'] ?= "#{resourcemanager}:8025"
    yarn['yarn.resourcemanager.scheduler.address'] ?= "#{resourcemanager}:8030"
    yarn['yarn.resourcemanager.address'] ?= "#{resourcemanager}:8050"
    yarn['yarn.resourcemanager.admin.address'] ?= "#{resourcemanager}:8041"
    # Comma separated list of paths. Use the list of directories from $YARN_LOCAL_DIR.  
    # For example, /grid/hadoop/hdfs/yarn/local,/grid1/hadoop/hdfs/yarn/local.
    yarn['yarn.nodemanager.local-dirs'] ?= "/grid/hadoop/hdfs/yarn/local,/grid1/hadoop/hdfs/yarn/local"
    yarn['yarn.nodemanager.local-dirs'] = yarn['yarn.nodemanager.local-dirs'].join ',' if Array.isArray yarn['yarn.nodemanager.local-dirs']
    # Use the list of directories from $YARN_LOCAL_LOG_DIR.  
    # For example, /grid/hadoop/yarn/logs /grid1/hadoop/yarn/logs /grid2/hadoop/yarn/logs
    yarn['yarn.nodemanager.log-dirs'] ?= "/grid/hadoop/hdfs/yarn/logs"
    yarn['yarn.nodemanager.log-dirs'] = yarn['yarn.nodemanager.log-dirs'].join ',' if Array.isArray yarn['yarn.nodemanager.log-dirs']
    # URL for job history server
    yarn['yarn.log.server.url'] ?= "http://#{jobhistoryserver}:19888/jobhistory/logs/"
    # URL for job history server
    yarn['yarn.resourcemanager.webapp.address'] ?= "#{resourcemanager}:8088"
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/yarn-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/yarn-site.xml"
      local_default: true
      properties: yarn
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_mapred()
  do_mapred = ->
    ctx.log 'Configure mapred-site.xml'
    # Enter your JobHistoryServer hostname
    mapred['mapreduce.jobhistory.address'] ?= "#{jobhistoryserver}:10020"
    # Enter your JobHistoryServer hostname.
    mapred['mapreduce.jobhistory.webapp.address'] ?= "#{jobhistoryserver}:19888"
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/mapred-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/mapred-site.xml"
      local_default: true
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
      destination: "#{hadoop_conf_dir}/taskcontroller.cfg"
      merge: true
      content:
        # 'mapred.local.dir': mapreduce_local_dir.join ','
        'mapred.local.dir': yarn_local_dir.join ','
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
      destination: "#{hadoop_conf_dir}/masters"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_slaves()
  do_slaves = ->
    ctx.log 'Configure slaves'
    ctx.write
      content: "#{slaves.join '\n'}"
      destination: "#{hadoop_conf_dir}/slaves"
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_core()

module.exports.push (ctx, next) ->
  @name "HDP # Install Compression"
  @timeout -1
  modified = false
  { hadoop_conf_dir } = ctx.config.hdp
  do_snappy = ->
    ctx.service [
      name: 'snappy'
    ,
      name: 'snappy-devel'
    ], (err, serviced) ->
      return next err if err
      return do_lzo() unless serviced
      ctx.execute
        cmd: 'ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/Linux-amd64-64/.'
      , (err, executed) ->
        return next err if err
        modified = true
        do_lzo()
  do_lzo = ->
    ctx.service [
      name: 'lzo'
    ,
      name: 'lzo-devel'
    ,
      name: 'hadoop-lzo'
    ,
      name: 'hadoop-lzo-native'
    ], (err, serviced) ->
      return next err if err
      modified = true if serviced
      do_core()
  do_core = ->
    ctx.log 'Configure core-site.xml'
    mapred = {}
    mapred['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/core-site.xml"
      properties: mapred
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_mapred()
  do_mapred = ->
    ctx.log 'Configure mapred-site.xml'
    mapred = {}
    mapred['mapreduce.admin.map.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
    mapred['mapreduce.admin.reduce.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/mapred-site.xml"
      properties: mapred
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_snappy()

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


    










