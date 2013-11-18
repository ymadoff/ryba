
url = require 'url'
mkcmd = require './hdp/mkcmd'

module.exports = []

module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/hdp_hdfs'

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_hdfs').configure ctx
  jobhistoryserver = (ctx.config.servers.filter (s) -> s.hdp?.jobhistoryserver)[0].host
  # Define Users and Groups
  ctx.config.hdp.mapred_user ?= 'mapred'
  # Options for mapred-site.xml
  ctx.config.hdp.mapred ?= {}
  ctx.config.hdp.mapred['mapreduce.job.counters.max'] ?= 120
  # http://developer.yahoo.com/hadoop/tutorial/module7.html
  # 1/2 * (cores/node) to 2 * (cores/node)
  ctx.config.hdp.mapred['mapred.tasktracker.map.tasks.maximum'] ?= ctx.config.hdp.dfs_data_dir.length
  ctx.config.hdp.mapred['mapred.tasktracker.reduce.tasks.maximum'] ?= Math.ceil(ctx.config.hdp.dfs_data_dir.length / 2)
  ctx.config.hdp.mapred['mapreduce.jobtracker.system.dir'] ?= '/mapred/system'
  ctx.config.hdp.mapred_log_dir ?= '/var/log/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#73
  ctx.config.hdp.mapred_pid_dir ?= '/var/run/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#94
  # [Configurations for MapReduce Applications](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuring_the_Hadoop_Daemons_in_Non-Secure_Mode)
  ctx.config.hdp.mapred['mapreduce.framework.name'] ?= 'yarn' # Execution framework set to Hadoop YARN.
  ctx.config.hdp.mapred['mapreduce.map.memory.mb'] ?= '4000' # Larger resource limit for maps.
  ctx.config.hdp.mapred['mapreduce.map.java.opts'] ?= '-Xmx2560M' # Larger heap-size for child jvms of maps.
  ctx.config.hdp.mapred['mapreduce.reduce.memory.mb'] ?= '3072' # Larger resource limit for reduces.
  ctx.config.hdp.mapred['mapreduce.reduce.java.opts'] ?= '-Xmx2560M' # Larger heap-size for child jvms of reduces.
  ctx.config.hdp.mapred['mapreduce.task.io.sort.mb'] ?= '1024' # Higher memory-limit while sorting data for efficiency.
  ctx.config.hdp.mapred['mapreduce.task.io.sort.factor'] ?= '100' # More streams merged at once while sorting files.
  ctx.config.hdp.mapred['mapreduce.reduce.shuffle.parallelcopies'] ?= '50' #  Higher number of parallel copies run by reduces to fetch outputs from very large number of maps.
  # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm_chap3.html
  # Optional: Configure MapReduce to use Snappy Compression
  # Complement core-site.xml configuration
  ctx.config.hdp.mapred['mapreduce.admin.map.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
  ctx.config.hdp.mapred['mapreduce.admin.reduce.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
  # [Configurations for MapReduce JobHistory Server](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuring_the_Hadoop_Daemons_in_Non-Secure_Mode)
  ctx.config.hdp.mapred['mapreduce.jobhistory.address'] ?= "#{jobhistoryserver}:10020" # MapReduce JobHistory Server host:port - Default port is 10020.
  ctx.config.hdp.mapred['mapreduce.jobhistory.webapp.address'] ?= "#{jobhistoryserver}:19888" # MapReduce JobHistory Server Web UI host:port - Default port is 19888.
  ctx.config.hdp.mapred['mapreduce.jobhistory.intermediate-done-dir'] ?= '/mr-history/tmp' # Directory where history files are written by MapReduce jobs.
  ctx.config.hdp.mapred['mapreduce.jobhistory.done-dir'] ?= '/mr-history/done' # Directory where history files are managed by the MR JobHistory Server.

module.exports.push (ctx, next) ->
  @name "HDP MapRed # Install Common"
  @timeout -1
  ctx.service [
    name: 'hadoop'
  ,
    name: 'hadoop-mapreduce'
  ,
    name: 'hadoop-client'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP Hadoop JHS # Users & Groups"
  {hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd mapred -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop MapReduce service\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name "HDP MapRed # System Directories"
  @timeout -1
  { mapred_user, hadoop_group, mapred_log_dir, mapred_pid_dir } = ctx.config.hdp
  modified = false
  do_log = ->
    ctx.log "Create hdfs and mapred log: #{mapred_log_dir}"
    ctx.mkdir
      destination: "#{mapred_log_dir}/#{mapred_user}"
      uid: mapred_user
      gid: hadoop_group
      mode: 0o0755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_pid()
  do_pid = ->
    ctx.log "Create hdfs and mapred pid: #{mapred_pid_dir}"
    ctx.mkdir
      destination: "#{mapred_pid_dir}/#{mapred_user}"
      uid: mapred_user
      gid: hadoop_group
      mode: 0o0755
    , (err, created) ->
      return next err if err
      modified = true if created
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_log()

module.exports.push (ctx, next) ->
  @name "HDP MapRed # Hadoop Configuration"
  { mapred, hadoop_conf_dir, mapred_queue_acls } = ctx.config.hdp
  modified = false
  do_mapred = ->
    ctx.log 'Configure mapred-site.xml'
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/mapred-site.xml"
      default: "#{__dirname}/hdp/core_hadoop/mapred-site.xml"
      local_default: true
      properties: mapred
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_mapred_queue_acls()
  do_mapred_queue_acls = ->
    ctx.log 'Configure mapred-queue-acls.xml'
    # Note, HDP-1.3.1 official doc is awkward, the example show an xml file.
    # http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.1/bk_installing_manually_book/content/rpm_chap3.html
    # The file is present inside HDP-2.0
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/mapred-queue-acls.xml"
      default: "#{__dirname}/hdp/core_hadoop/mapred-queue-acls.xml"
      local_default: true
      properties: mapred_queue_acls
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_mapred()

module.exports.push (ctx, next) ->
  @name 'HDP MapRed # Kerberos'
  {hadoop_conf_dir} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  mapred = {}
  mapred['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
  mapred['mapreduce.jobhistory.principal'] ?= "jhs/_HOST@#{realm}"
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/mapred-site.xml"
    properties: mapred
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

###
Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
###
module.exports.push (ctx, next) ->
  {hadoop_group, hdfs_user, yarn, yarn_user, mapred, mapred_user} = ctx.config.hdp
  @name 'HDP MapRed # HDFS layout'
  ok = false
  do_mapreduce_jobtracker_system_dir = ->
    mapreduce_jobtracker_system_dir = mapred['mapreduce.jobtracker.system.dir']
    ctx.log "Create #{mapreduce_jobtracker_system_dir}"
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d #{mapreduce_jobtracker_system_dir}; then exit 1; fi
      hadoop fs -mkdir -p #{mapreduce_jobtracker_system_dir}
      hadoop fs -chown #{mapred_user}:#{hadoop_group} #{mapreduce_jobtracker_system_dir}
      hadoop fs -chmod 755 #{mapreduce_jobtracker_system_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_mapreduce_jobhistory_intermediate_done_dir()
  do_mapreduce_jobhistory_intermediate_done_dir = ->
    # Default value for "mapreduce.jobhistory.intermediate-done-dir" 
    # is "${yarn.app.mapreduce.am.staging-dir}/history/done_intermediate"
    # where "yarn.app.mapreduce.am.staging-dir"
    # is "/tmp/hadoop-yarn/staging"
    mapreduce_jobhistory_intermediate_done_dir = mapred['mapreduce.jobhistory.intermediate-done-dir']
    ctx.log "Create #{mapreduce_jobhistory_intermediate_done_dir}"
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d #{mapreduce_jobhistory_intermediate_done_dir}; then exit 1; fi
      hadoop fs -mkdir -p #{mapreduce_jobhistory_intermediate_done_dir}
      hadoop fs -chown #{mapred_user}:#{hadoop_group} #{mapreduce_jobhistory_intermediate_done_dir}
      hadoop fs -chmod 777 #{mapreduce_jobhistory_intermediate_done_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_mapreduce_jobhistory_done_dir()
  do_mapreduce_jobhistory_done_dir = ->
    # Default value for "mapreduce.jobhistory.done-dir" 
    # is "${yarn.app.mapreduce.am.staging-dir}/history/done"
    # where "yarn.app.mapreduce.am.staging-dir"
    # is "/tmp/hadoop-yarn/staging"
    mapreduce_jobhistory_done_dir = mapred['mapreduce.jobhistory.done-dir']
    ctx.log "Create #{mapreduce_jobhistory_done_dir}"
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d #{mapreduce_jobhistory_done_dir}; then exit 1; fi
      hadoop fs -mkdir -p #{mapreduce_jobhistory_done_dir}
      hadoop fs -chown #{mapred_user}:#{hadoop_group} #{mapreduce_jobhistory_done_dir}
      hadoop fs -chmod 750 #{mapreduce_jobhistory_done_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_end()
  do_end = ->
    next null, if ok then ctx.OK else ctx.PASS
  do_mapreduce_jobtracker_system_dir()

###
Test JobTracker
---------------
Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated 
by this action is not present on HDFS. Delete this directory 
to re-execute the check.
###
# module.exports.push (ctx, next) ->
#   @name 'HDP Check # Test ResourceManager UI'
#   ctx.execute
#     cmd: 'curl http://#{}:8088'
#   , (err, executed, stdout) ->
#     return next err if err
#     console.log stdout
#     next err, ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP MapRed # Check'
  @timeout -1
  ctx.execute
    cmd: mkcmd.test ctx, """
    if hadoop fs -test -d 10gsort; then exit 1; fi
    hadoop fs -mkdir 10gsort
    hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2*.jar teragen 100 10gsort/input
    hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples-2*.jar terasort 10gsort/input 10gsort/output
    """
    code_skipped: 1
  , (err, executed, stdout) ->
    next err, if executed then ctx.OK else ctx.PASS




