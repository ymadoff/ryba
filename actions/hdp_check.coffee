
hdp = require './hdp'
lifecycle = require './hdp/lifecycle'
krb5_client = require './krb5_client'
mkprincipal = require './krb5/lib/mkprincipal'
module.exports = []

mkcmdhdfs = (ctx, cmd) ->
  kerberos = ctx.hasAction('histi/actions/hdp_krb5')
  unless kerberos
  then "su -l #{hdfs_user} -c \"#{cmd}\""
  else "kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {\n#{cmd}\n}"

mkcmdtest = (ctx, cmd) ->
  kerberos = ctx.hasAction('histi/actions/hdp_krb5')
  unless kerberos
  then "su -l #{test_user} -c \"#{cmd}\""
  else "kinit -kt /etc/security/keytabs/test.headless.keytab test && {\n#{cmd}\n}"

module.exports.push (ctx) ->
  hdp.configure ctx
  ctx.config.hdp.force_check ?= false
  krb5_client.configure ctx

module.exports.push (ctx, next) ->
  {dfs_name_dir, hdfs_user, format} = ctx.config.hdp
  return next() unless format
  @name 'HDP Check # Format'
  ctx.log "Format HDFS if #{dfs_name_dir[0]} does not exist"
  ctx.execute
    cmd: "yes 'Y' | su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop namenode -format\""
    not_if_exists: "#{dfs_name_dir[0]}/current/fsimage"
    # should_exist: "#{dfs_name_dir}/current/fsimage"
  , (err, executed) ->
    return next err if err
    return next null, ctx.PASS unless executed
    lifecycle.nn_start ctx, (err, started) ->
      next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'HDP Check # Upgrade'
  count = (callback) ->
    ctx.execute
      cmd: 'cat /var/log/hadoop/hdfs/hadoop-hdfs-namenode-hadoop1.hadoop.log | grep "upgrade to version" | wc -l'
    , (err, executed, stdout) ->
      callback err, parseInt stdout.trim(), 10
  ctx.log 'Dont try to upgrade if namenode is running'
  lifecycle.nn_running ctx, (err, running) ->
    return next err if err
    return next null, ctx.DISABLED if running
    ctx.log 'Count how many upgrade msg in log'
    count (err, c1) ->
      return next err if err
      ctx.log 'Start namenode'
      lifecycle.nn_start ctx, (err, started) ->
        return next err if err
        return next null, ctx.PASS if started
        ctx.log 'Count again'
        count (err, c2) ->
          return next err if err
          return next null, ctx.PASS if c1 is c2
          return next null, 'Upgrade manually'

###
Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
###
module.exports.push (ctx, next) ->
  {hdfs_user, yarn} = ctx.config.hdp
  @name 'HDP Check # HDFS layout'
  ok = false
  do_root = ->
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      hadoop fs -chmod 755 /
      """
    , (err, executed, stdout) ->
      return next err if err
      do_tmp()
  do_tmp = ->
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      if hadoop fs -test -d /tmp; then exit 1; fi
      hadoop fs -mkdir /tmp
      hadoop fs -chown hdfs:hadoop /tmp
      hadoop fs -chmod 777 /tmp
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_user()
  do_user = ->
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      if hadoop fs -test -d /user; then exit 1; fi
      hadoop fs -mkdir /user
      hadoop fs -chown hdfs:hadoop /user
      hadoop fs -chmod 755 /user
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_remove_app_log_dir()
  do_remove_app_log_dir = ->
    # Default value for "yarn.nodemanager.remote-app-log-dir" is "/tmp/logs"
    remove_app_log_dir = yarn['yarn.nodemanager.remote-app-log-dir']
    remove_app_log_dir ?= "/tmp/logs"
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      if hadoop fs -test -d #{remove_app_log_dir}; then exit 1; fi
      hadoop fs -mkdir #{remove_app_log_dir}
      hadoop fs -chown yarn:hadoop #{remove_app_log_dir}
      hadoop fs -chmod 777 #{remove_app_log_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_mapreduce_am_staging_dir()
  do_mapreduce_am_staging_dir = ->
    # Default value for "mapreduce.jobhistory.intermediate-done-dir" 
    # is "${yarn.app.mapreduce.am.staging-dir}/history/done_intermediate"
    # where "yarn.app.mapreduce.am.staging-dir"
    # is "/tmp/hadoop-yarn/staging"
    mapreduce_am_staging_dir = yarn['mapreduce.jobhistory.intermediate-done-dir']
    mapreduce_am_staging_dir ?= "/tmp/hadoop-yarn/staging/history/done_intermediate"
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      if hadoop fs -test -d #{mapreduce_am_staging_dir}; then exit 1; fi
      hadoop fs -mkdir #{mapreduce_am_staging_dir}
      hadoop fs -chown mapred:hadoop #{mapreduce_am_staging_dir}
      hadoop fs -chmod 777 #{mapreduce_am_staging_dir}
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      ok = true if executed
      do_end()
  do_mapreduce_jobhistory_done_dir = ->
    # Default value for "mapreduce.jobhistory.done-dir" 
    # is "${yarn.app.mapreduce.am.staging-dir}/history/done"
    # where "yarn.app.mapreduce.am.staging-dir"
    # is "/tmp/hadoop-yarn/staging"
    mapreduce_jobhistory_done_dir = yarn['mapreduce.jobhistory.done-dir']
    mapreduce_jobhistory_done_dir ?= "/tmp/hadoop-yarn/staging/history/done"
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      if hadoop fs -test -d #{mapreduce_jobhistory_done_dir}; then exit 1; fi
      hadoop fs -mkdir #{mapreduce_jobhistory_done_dir}
      hadoop fs -chown mapred:hadoop #{mapreduce_jobhistory_done_dir}
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
  {realm, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_client
  @name 'HDP Check # Create User "test"'
  @timeout -1
  modified = false
  do_user = ->
    unless ctx.hasAction('histi/actions/hdp_krb5')
    then do_user_unix()
    else do_user_krb5()
  do_user_unix = ->
    ctx.execute
      cmd: "useradd test -c \"Used by Hadoop to test\" -r -M -g #{hadoop_group}"
      code: 0
      code_skipped: 9
    , (err, created) ->
      return next err if err
      modified = true if created
      do_run()
  do_user_krb5 = ->
    mkprincipal
      principal: "test@#{realm}"
      randkey: true
      keytab: "/etc/security/keytabs/test.headless.keytab"
      ssh: ctx.ssh
      log: ctx.log
      stdout: ctx.log.out
      stderr: ctx.log.err
      kadmin_principal: kadmin_principal
      kadmin_password: kadmin_password
      admin_server: admin_server
    , (err, created) ->
      return next err if err
      modified = true if created
      do_run()
  do_run = ->
    ctx.execute
      cmd: mkcmdhdfs ctx, """
      if hadoop fs -ls /user/test 2>/dev/null; then exit 1; fi
      hadoop fs -mkdir /user/test
      hadoop fs -chown test /user/test
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      modified = true if executed
      next err, if modified then ctx.OK else ctx.PASS
  do_user()

module.exports.push (ctx, next) ->
  {hdfs_user} = ctx.config.hdp
  @name 'HDP Check # Test HDFS'
  ctx.execute
    cmd: mkcmdtest ctx, """
    if hadoop fs -test -d /user/test/hdfs; then exit 1; fi
    hadoop fs -put /etc/passwd /user/test/hdfs
    """
    code_skipped: 1
  , (err, executed, stdout) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Test JobTracker
---------------
Run the "teragen" and "terasort" hadoop examples. Will only
be executed if the directory "/user/test/10gsort" generated 
by this action is not present on HDFS. Delete this directory 
to re-execute the check.
###
module.exports.push (ctx, next) ->
  @name 'HDP Check # Test JobTracker'
  @timeout -1
  ctx.execute
    cmd: mkcmdtest ctx, """
    if hadoop fs -test -d /user/test/10gsort; then exit 1; fi
    hadoop fs -mkdir /user/test/10gsort
    hadoop jar /usr/lib/hadoop/hadoop-examples.jar teragen 100000000 /user/test/10gsort/input
    hadoop jar /usr/lib/hadoop/hadoop-examples.jar terasort /user/test/10gsort/input /user/test/10gsort/output
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
  @name 'HDP Check # Test WebHDFS'
  @timeout -1
  do_init = ->
    ctx.execute
      cmd: mkcmdtest ctx, """
        if hadoop fs -test -e /user/test/webhdfs; then exit 1; fi
        hadoop fs -touchz /user/test/webhdfs
        kdetroy
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      return do_spnego() if force_check
      return next null, ctx.PASS unless executed
      do_spnego()
  do_spnego = ->
    ctx.execute
      cmd: mkcmdtest ctx, """
      curl -s --negotiate -u : "http://#{namenode}:#{namenode_port}/webhdfs/v1/user/test?op=LISTSTATUS"
      kdestroy
      """
    , (err, executed, stdout) ->
      return next err if err
      count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is 'webhdfs').length
      return next null, ctx.FAILED unless count
      do_token()
  do_token = ->
    ctx.execute
      cmd: mkcmdtest ctx, """
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





