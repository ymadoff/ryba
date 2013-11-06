
lifecycle = require './hdp/lifecycle'
mkcmd = require './hdp/mkcmd'
module.exports = []

module.exports.push 'histi/actions/hdp_hdfs'

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hdfs').configure ctx
  require('./krb5_client').configure ctx

module.exports.push (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  @name 'HDP Hadoop NN # Kerberos'
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

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop NN # HDFS User'
  {hdfs_user} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc
    principal: "#{hdfs_user}@#{realm}"
    password: 'hdfs123'
    # randkey: true
    # keytab: "/etc/security/keytabs/hdfs.headless.keytab"
    # uid: 'hdfs'
    # gid: 'hadoop'
    # mode: '600'
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    return next err if err
    next null, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hdfs_user, hadoop_group, security} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  @name 'HDP Hadoop NN # Test User'
  @timeout -1
  modified = false
  do_user = ->
    if security is 'kerberos'
    then do_user_krb5()
    else do_user_unix()
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
    ctx.krb5_addprinc
      principal: "test@#{realm}"
      password: 'test123'
      # randkey: true
      # keytab: "/etc/security/keytabs/test.headless.keytab"
      kadmin_principal: kadmin_principal
      kadmin_password: kadmin_password
      kadmin_server: kadmin_server
    , (err, created) ->
      return next err if err
      modified = true if created
      do_run()
  do_run = ->
    ctx.execute
      cmd: mkcmd.hdfs ctx, """
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
  {dfs_name_dir, hdfs_user, format, cluster_name} = ctx.config.hdp
  return next() unless format
  @name 'HDP Hadoop NN # Format'
  ctx.log "Format HDFS if #{dfs_name_dir[0]} does not exist"
  ctx.execute
    #  su -l hdfs -c "hdfs namenode -format duzy"
    # cmd: "yes 'Y' | su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop namenode -format\""
    cmd: "su -l #{hdfs_user} -c \"hdfs namenode -format #{cluster_name}\""
    # not_if_exists: "#{dfs_name_dir[0]}/current/fsimage"
    not_if_exists: "#{dfs_name_dir[0]}/current/VERSION"
  , (err, executed) ->
    return next err if err
    return next null, if executed then ctx.OK else ctx.PASS
    lifecycle.nn_start ctx, (err, started) ->
      return next err if err
      lifecycle.dn_start ctx, (err, started) ->
        next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop NN # Upgrade'
  {hdfs_log_dir} = ctx.config.hdp
  count = (callback) ->
    ctx.execute
      cmd: "cat #{hdfs_log_dir}/*/*.log | grep 'upgrade to version' | wc -l"
    , (err, executed, stdout) ->
      callback err, parseInt(stdout.trim(), 10) or 0
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
          return next new Error 'Upgrade manually'

module.exports.push (ctx, next) ->
  {namenode} = ctx.config.hdp
  return next() unless namenode
  @name "HDP Hadoop NN # Start"
  lifecycle.nn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS




