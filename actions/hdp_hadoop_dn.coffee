
lifecycle = require './hdp/lifecycle'
mkcmd = require './hdp/mkcmd'
module.exports = []

module.exports.push 'histi/actions/hdp_hdfs'

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hdfs').configure ctx
  require('./krb5_client').configure ctx
  ctx.config.hdp.force_check ?= false

module.exports.push (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  @name 'HDP Hadoop DN # Kerberos'
  ctx.krb5_addprinc 
    principal: "dn/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/dn.service.keytab"
    uid: 'hdfs'
    gid: 'hadoop'
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop DN # Start'
  # lifecycle.nn_start ctx, (err, started) ->
  #   return next err if err
  #   lifecycle.dn_start ctx, (err, started) ->
  #     next err, ctx.OK
  lifecycle.dn_start ctx, (err, started) ->
    next err, ctx.OK

###
Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
###
module.exports.push (ctx, next) ->
  {hadoop_group, hdfs_user, yarn, yarn_user, mapred, mapred_user} = ctx.config.hdp
  @name 'HDP Hadoop DN # HDFS layout'
  ok = false
  do_root = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      hadoop fs -chmod 755 /
      """
    , (err, executed, stdout) ->
      return next err if err
      do_tmp()
  do_tmp = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d /tmp; then exit 1; fi
      hadoop fs -mkdir /tmp
      hadoop fs -chown #{hdfs_user}:#{hadoop_group} /tmp
      hadoop fs -chmod 777 /tmp
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_user()
  do_user = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d /user; then exit 1; fi
      hadoop fs -mkdir /user
      hadoop fs -chown #{hdfs_user}:#{hadoop_group} /user
      hadoop fs -chmod 755 /user
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_jobhistory_server()
  do_jobhistory_server = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d /mr-history; then exit 1; fi
      hadoop fs -mkdir -p /mr-history/tmp
      hadoop fs -chmod -R 1777 /mr-history/tmp
      hadoop fs -mkdir -p /mr-history/done
      hadoop fs -chmod -R 1777 /mr-history/done
      hadoop fs -chown -R #{mapred_user}:#{hadoop_group} /mr-history
      hadoop fs -mkdir -p /app-logs
      hadoop fs -chmod -R 1777 /app-logs 
      hadoop fs -chown #{yarn_user} /app-logs 
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_remote_app_log_dir()
  do_remote_app_log_dir = ->
    # Default value for "yarn.nodemanager.remote-app-log-dir" is "/tmp/logs"
    remote_app_log_dir = yarn['yarn.nodemanager.remote-app-log-dir']
    ctx.log "Create #{remote_app_log_dir}"
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
      if hadoop fs -test -d #{remote_app_log_dir}; then exit 1; fi
      hadoop fs -mkdir -p #{remote_app_log_dir}
      hadoop fs -chown #{yarn_user}:#{hadoop_group} #{remote_app_log_dir}
      hadoop fs -chmod 777 #{remote_app_log_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_mapreduce_jobtracker_system_dir()
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
  do_root()

module.exports.push (ctx, next) ->
  {hdfs_user} = ctx.config.hdp
  @name 'HDP Hadoop DN # Test HDFS'
  ctx.execute
    cmd: mkcmd.test ctx, """
    if hadoop fs -test -d /user/test/hdfs_#{ctx.config.host}; then exit 1; fi
    hadoop fs -put /etc/passwd /user/test/hdfs_#{ctx.config.host}
    """
    code_skipped: 1
  , (err, executed, stdout) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Test WebHDFS
------------
Test the Kerberos SPNEGO and the Hadoop delegation token. Will only be 
executed if the file "/user/test/webhdfs" generated by this action 
is not present on HDFS.

Read [Delegation Tokens in Hadoop Security ](http://www.kodkast.com/blogs/hadoop/delegation-tokens-in-hadoop-security) 
for more information.
###
module.exports.push (ctx, next) ->
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  {namenode_port, force_check} = ctx.config.hdp
  @name 'HDP Hadoop DN # Test WebHDFS'
  @timeout -1
  do_init = ->
    ctx.execute
      cmd: mkcmd.test ctx, """
        if hadoop fs -test -e /user/test/webhdfs; then exit 1; fi
        hadoop fs -touchz /user/test/webhdfs
        kdestroy
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      return do_spnego() if force_check
      return next null, ctx.PASS unless executed
      do_spnego()
  do_spnego = ->
    ctx.execute
      cmd: mkcmd.test ctx, """
      curl -s --negotiate -u : "http://#{namenode}:#{namenode_port}/webhdfs/v1/user/test?op=LISTSTATUS"
      kdestroy
      """
    , (err, executed, stdout) ->
      return next err if err
      console.log stdout
      count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is 'webhdfs').length
      return next null, ctx.FAILED unless count
      do_token()
  do_token = ->
    ctx.execute
      cmd: mkcmd.test ctx, """
      curl -s --negotiate -u : "http://#{namenode}:#{namenode_port}/webhdfs/v1/?op=GETDELEGATIONTOKEN"
      kdestroy
      """
    , (err, executed, stdout) ->
      return next err if err
      token = JSON.parse(stdout).Token.urlString
      ctx.execute
        cmd: """
        curl -s "http://#{namenode}:#{namenode_port}/webhdfs/v1/user/test?delegation=#{token}&op=LISTSTATUS"
        """
      , (err, executed, stdout) ->
        return next err if err
        count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is 'webhdfs').length
        return next null, ctx.FAILED unless count
        do_end()
  do_end = ->
    next null, ctx.OK
  do_init()






