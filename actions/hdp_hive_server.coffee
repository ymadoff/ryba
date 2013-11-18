
path = require 'path'
mkcmd = require './hdp/mkcmd'
lifecycle = require './hdp/lifecycle'
mkcmd = require './hdp/mkcmd'
module.exports = []

module.exports.push 'histi/actions/mysql_client'
module.exports.push 'histi/actions/hdp_hive_client'

module.exports.push (ctx) ->
  require('./hdp_hive_client').configure ctx
  # Define Users and Groups
  ctx.config.hdp.hive_user ?= 'hive'
  ctx.config.hdp.webhcat_user ?= 'webhcat'
  ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
  ctx.config.hdp.hive_pid_dir ?= '/var/run/hive'
  ctx.config.hdp.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
  ctx.config.hdp.webhcat_log_dir ?= '/var/log/webhcat/webhcat'
  ctx.config.hdp.webhcat_pid_dir ?= '/var/run/webhcat'
  ctx.config.hdp.hive_libs ?= []

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat server # Configure'
  {realm} = ctx.config.krb5_client
  {hive_site} = ctx.config.hdp
  ctx.hconfigure
    destination: '/etc/hive/conf/hive-site.xml'
    default: "#{__dirname}/hdp/hive/hive-site.xml"
    local_default: true
    properties: hive_site
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP Hive & HCat server # Users"
  {hive_user, hadoop_group, webhcat_user} = ctx.config.hdp
  cmd = (cmd) ->
    cmd: cmd
    code: 0
    code_skipped: 9
  cmds = []
  cmds.push cmd "groupadd hadoop"
  cmds.push cmd "useradd #{hive_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop Hive service\""
  cmds.push cmd "useradd #{webhcat_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop HCatalog/WebHCat service\"" if ctx.config.hdp.hcatalog_server or ctx.config.hdp.webhcat
  ctx.execute parallel: 1, cmds, (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hive_libs} = ctx.config.hdp
  return next() unless hive_libs.length
  @name 'HDP Hive & HCat server # Libs'
  uploads = for lib in hive_libs
    source: lib
    destination: "/usr/lib/hive/lib/#{path.basename lib}"
  ctx.upload uploads, (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat server # Layout'
  {hive_log_dir, hive_user, hadoop_group, mode} = ctx.config.hdp
  ctx.mkdir
    destination: hive_log_dir
    uid: hive_user
    gid: hadoop_group
    mode: 0o0755
  , (err, modified) ->
    return next err, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hdfs_user, hive_user, hadoop_group} = ctx.config.hdp
  @name 'HDP Hive & HCat server # Layout'
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  ctx.connect namenode, (err, ssh) ->
    return next err if err
    # kerberos = true
    modified = false
    do_user = ->
      ctx.execute
        ssh: ssh
        cmd: mkcmd.hdfs ctx, """
        if hadoop fs -ls /user/#{hive_user}/warehouse &>/dev/null; then exit 1; fi
        hadoop fs -mkdir -p /user/#{hive_user}; 
        hadoop fs -chown -R #{hive_user}:#{hadoop_group} /user/#{hive_user}
        """
        code_skipped: 1
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_warehouse()
    do_warehouse = ->
      ctx.execute
        ssh: ssh
        cmd: mkcmd.hdfs ctx, """
        if hadoop fs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
        hadoop fs -mkdir -p /apps/#{hive_user};
        hadoop fs -mkdir /apps/#{hive_user}/warehouse; 
        hadoop fs -chown -R #{hive_user}:#{hadoop_group} /apps/#{hive_user}
        hadoop fs -chmod -R 775 /apps/#{hive_user};
        """
        code_skipped: 3
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_scratch()
    do_scratch = ->
      ctx.execute
        ssh: ssh
        cmd: mkcmd.hdfs ctx, """
        if hadoop fs -ls /tmp/scratch &> /dev/null; then exit 1; fi
        hadoop fs -mkdir /tmp 2>/dev/null;
        hadoop fs -mkdir /tmp/scratch;
        hadoop fs -chown #{hive_user}:#{hadoop_group} /tmp/scratch;
        hadoop fs -chmod -R 777 /tmp/scratch;
        """
        code_skipped: 1
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_end()
    do_end = ->
      next null, if modified then ctx.OK else ctx.PASS
    do_warehouse()

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat server # Start Metastore'
  lifecycle.hive_metastore_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat server # Start Server2'
  lifecycle.hive_server2_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat server # Check'
  # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
  # !connect jdbc:hive2://big3.big:10000/default;principal=hive/big3.big@ADALTAS.COM 
  next null, ctx.TODO






