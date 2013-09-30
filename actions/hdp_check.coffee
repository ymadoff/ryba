
hdp = require './hdp'
krb5_client = require './krb5_client'
mkprincipal = require './krb5/lib/mkprincipal'
module.exports = []

module.exports.push (ctx) ->
  hdp.configure ctx
  ctx.config.hdp.force_check ?= false
  krb5_client.configure ctx

module.exports.push (ctx, next) ->
  {dfs_name_dir, hdfs_user, format} = ctx.config.hdp
  return next() unless format
  @name 'HDP Check # Format'
  # misc.file.exists ctx.ssh, '/data/1/nn/current/VERSION', (err, exists) ->
  ctx.log "Format HDFS if #{dfs_name_dir[0]} does not exist"
  ctx.execute
    cmd: "yes 'Y' | su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop namenode -format\""
    not_if_exists: "#{dfs_name_dir[0]}/current/fsimage"
    # should_exist: "#{dfs_name_dir}/current/fsimage"
  , (err, executed) ->
    return next err if err
    return next null, ctx.PASS unless executed
    ctx.execute
      cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start namenode\""
    , (err) ->
      next err, ctx.OK


# # TODO: WE NEED TO HANDLE DIRECTORY LAYOUT
# module.exports.push (ctx, next) ->
#   {hdfs_user} = ctx.config.hdp
#   @name 'HDP Check # TEST KRB5 TICKET'
#   ctx.execute
#     cmd: """
#     kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {
#       hadoop fs -ls /mapred || {
#         hadoop fs -mkdir /mapred && hadoop fs -chown -R mapred /mapred
#       } 
#     }
#     """
#   , (err, executed, stdout) ->
#     console.log '----------------------'
#     console.log stdout
#     console.log '----------------------'
#     next err, if executed then ctx.OK else ctx.PASS

# PROBLEM: kerberos isn't active over ssh
# TODO: Command to execute: https://github.com/apache/bigtop/blob/master/bigtop-packages/src/common/hadoop/init-hdfs.sh
# ###
# Create MapReduce directory layout.
# http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap4.html
# ###
# module.exports.push (ctx, next) ->
#   {hdfs_user} = ctx.config.hdp
#   @name 'HDP Check # MapReduce layout'
#   # todo; need to check if namenode and datanode are started
#   kerberos = true
#   cmd = 'if hadoop fs -ls /mapred; then exit 1; else hadoop fs -mkdir /mapred && hadoop fs -chown -R mapred /mapred; fi'
#   unless kerberos
#     ctx.execute
#       cmd: "su -l #{hdfs_user} -c \"#{cmd}\""
#     , (err, executed) ->
#   else
#     ctx.execute
#       cmd: """
#       kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs
#       #{cmd}
#       """
#       code_skipped: 1
#     , (err, executed, stdout) ->
#       next err, if executed then ctx.OK else ctx.PASS

# module.exports.push (ctx, next) ->
#   {hdfs_user} = ctx.config.hdp
#   @name 'HDP Check # Smoke Test'
#   return next null, ctx.TODO
#   ctx.execute
#     cmd: "su -l #{hdfs_user} -c \"/usr/lib/hadoop/bin/hadoop-daemon.sh --config /etc/hadoop/conf start namenode\""
#   , (err, executed) ->
#     return next err if err
#     return next null, ctx.PASS unless executed
#     ctx.execute
#       cmd: ""
#     , (err) ->
#       next err, ctx.OK

module.exports.push (ctx, next) ->
  {hdfs_user} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_client
  @name 'HDP Check # Create User "test"'
  @timeout -1
  modified = false
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
    ctx.execute
      cmd: """
      kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {
        if hadoop fs -ls /user/test 2>/dev/null; then exit 1; fi
        hadoop fs -mkdir /user/test
        hadoop fs -chown test /user/test
      }
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      modified = true if executed
      next err, if modified then ctx.OK else ctx.PASS

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
    cmd: """
    kinit -kt /etc/security/keytabs/test.headless.keytab test && {
      if hadoop fs -test -d /user/test/10gsort; then exit 1; fi
      hadoop fs -mkdir /user/test/10gsort
      hadoop jar /usr/lib/hadoop/hadoop-examples.jar teragen 100000000 /user/test/10gsort/input
      hadoop jar /usr/lib/hadoop/hadoop-examples.jar terasort /user/test/10gsort/input /user/test/10gsort/output
    }
    """
    code_skipped: 1
  , (err, executed, stdout) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Test WebHDFS
------------
Test the Kerberos SPNEGO and the Hadoop delegation token. Will only be 
executed if the file "/user/test/empty" generated by this action 
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
      cmd: """
      kinit -kt /etc/security/keytabs/test.headless.keytab test && {
        if hadoop fs -test -e /user/test/empty; then exit 1; fi
        hadoop fs -touchz /user/test/empty
        kdetroy
      }
      """
      code_skipped: 1
    , (err, executed, stdout) ->
      return next err if err
      return do_spnego() if force_check
      return next null, ctx.PASS unless executed
      do_spnego()
  do_spnego = ->
    ctx.execute
      cmd: """
      kinit -kt /etc/security/keytabs/test.headless.keytab test && {
        curl -s --negotiate -u : "http://#{namenode}:#{namenode_port}/webhdfs/v1/user/test?op=LISTSTATUS"
        kdestroy
      }
      """
    , (err, executed, stdout) ->
      return next err if err
      count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is 'empty').length
      return next null, ctx.FAILED unless count
      do_token()
  do_token = ->
    ctx.execute
      cmd: """
      kinit -kt /etc/security/keytabs/test.headless.keytab test && {
        curl -s --negotiate -u : "http://#{namenode}:#{namenode_port}/webhdfs/v1/?op=GETDELEGATIONTOKEN"
        kdestroy
      }
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
        count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is 'empty').length
        return next null, ctx.FAILED unless count
        do_end()
  do_end = ->
    next null, ctx.OK
  do_init()





