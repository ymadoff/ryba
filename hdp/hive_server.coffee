
path = require 'path'
mkcmd = require './lib/mkcmd'
lifecycle = require './lib/lifecycle'
mkcmd = require './lib/mkcmd'
module.exports = []

# Install the mysql connector
module.exports.push 'histi/actions/mysql_client'
# Deploy the HDP repository
# Configure "core-site.xml" and "hadoop-env.sh"
module.exports.push 'histi/hdp/core'
# Install client to create new Hive principal
module.exports.push 'histi/actions/krb5_client'
# Install the Hive and HCatalog service
module.exports.push 'histi/hdp/hive_'
# Validate DNS lookup
module.exports.push 'histi/actions/dns'


module.exports.push module.exports.configure = (ctx) ->
  require('../actions/mysql_server').configure ctx
  require('./hive_').configure ctx
  require('../actions/nc').configure ctx
  # Define Users and Groups
  # ctx.config.hdp.mysql_user ?= 'hive'
  # ctx.config.hdp.mysql_password ?= 'hive123'
  # ctx.config.hdp.webhcat_user ?= 'webhcat'
  ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
  ctx.config.hdp.hive_pid_dir ?= '/var/run/hive'
  ctx.config.hdp.hive_site['datanucleus.autoCreateTables'] ?= 'true'
  ctx.config.hdp.hive_libs ?= []

module.exports.push name: 'HDP Hive & HCat client # Configure', callback: (ctx, next) ->
  {hive_site, hive_user, hive_group, hive_conf_dir} = ctx.config.hdp
  ctx.hconfigure
    destination: "#{hive_conf_dir}/hive-site.xml"
    default: "#{__dirname}/files/hive/hive-site.xml"
    local_default: true
    properties: hive_site
    merge: true
  , (err, configured) ->
    return next err if err
    ctx.execute
      cmd: """
      chown -R #{hive_user}:#{hive_group} #{hive_conf_dir}/
      chmod -R 755 #{hive_conf_dir}
      """
    , (err) ->
      next err, if configured then ctx.OK else ctx.PASS

# #http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
# #http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
# module.exports.push name: 'HDP Hive & HCat server # Users', callback: (ctx, next) ->
#   {hive_user, hadoop_group, webhcat_user} = ctx.config.hdp
#   cmd = (cmd) ->
#     cmd: cmd
#     code: 0
#     code_skipped: 9
#   cmds = []
#   cmds.push cmd "groupadd #{hadoop_group}"
#   # cmds.push cmd "usermod -a -G hadoop #{hive_user}"
#   # cmds.push cmd "usermod -a -G hadoop #{webhcat_user}"
#   # Create the hive user as system (-r) with a home directory (-m)
#   cmds.push cmd "useradd #{hive_user} -r -m -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop Hive service\""
#   cmds.push cmd "useradd #{webhcat_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop HCatalog/WebHCat service\"" if ctx.config.hdp.hcatalog_server or ctx.config.hdp.webhcat
#   ctx.execute parallel: 1, cmds, (err, executed) ->
#     next err, if executed then ctx.OK else ctx.PASS


module.exports.push name: 'HDP Hive & HCat server # Libs', callback: (ctx, next) ->
  {hive_libs} = ctx.config.hdp
  return next() unless hive_libs.length
  uploads = for lib in hive_libs
    source: lib
    destination: "/usr/lib/hive/lib/#{path.basename lib}"
  ctx.upload uploads, (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat server # Driver', callback: (ctx, next) ->
  ctx.link
    source: '/usr/share/java/mysql-connector-java.jar'
    destination: '/usr/lib/hive/lib/mysql-connector-java.jar'
  , (err, configured) ->
    return next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat server # Kerberos', callback: (ctx, next) ->
  {hive_user, hive_group} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.mkdir
    destination: '/etc/security/keytabs'
    uid: 'root'
    gid: 'hadoop'
    mode: 0o755
  , (err, created) ->
    return next err if err
    ctx.krb5_addprinc
      principal: "hive/#{ctx.config.host}@#{realm}"
      randkey: true
      keytab: "/etc/security/keytabs/hive.service.keytab"
      uid: hive_user
      gid: hive_group
      kadmin_principal: kadmin_principal
      kadmin_password: kadmin_password
      kadmin_server: kadmin_server
    # ,
    #   principal: "hcat/#{ctx.config.host}@#{realm}"
    #   randkey: true
    #   keytab: "/etc/security/keytabs/hcat.service.keytab"
    #   uid: 'hcat'
    #   gid: 'hadoop'
    , (err, created) ->
      return next err if err
      next null, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat server # Logs', callback: (ctx, next) ->
  ctx.write [
    source: "#{__dirname}/files/hive/hive-exec-log4j.properties.template"
    local_source: true
    destination: '/etc/hive/conf/hive-exec-log4j.properties'
  ,
    source: "#{__dirname}/files/hive/hive-log4j.properties.template"
    local_source: true
    destination: '/etc/hive/conf/hive-log4j.properties'
  ], (err, written) ->
    return next err, if written then ctx.OK else ctx.PASS

# module.exports.push name: 'HDP Hive & HCat server # Log', callback: (ctx, next) ->
#   {hive_log_dir, hive_user, hadoop_group, mode} = ctx.config.hdp
#   ctx.mkdir
#     destination: hive_log_dir
#     uid: hive_user
#     gid: hadoop_group
#     mode: 0o0755
#   , (err, modified) ->
#     return next err, if modified then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat server # Layout', callback: (ctx, next) ->
  {hdfs_user, hive_user, hive_group} = ctx.config.hdp
  namenode = ctx.hosts_with_module 'histi/hdp/hdfs_nn', 1
  ctx.log "SSH connection to #{namenode}"
  ctx.connect namenode, (err, ssh) ->
    return next err if err
    # kerberos = true
    modified = false
    do_user = ->
      ctx.execute
        ssh: ssh
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -ls /user/#{hive_user}/warehouse &>/dev/null; then exit 1; fi
        hdfs dfs -mkdir -p /user/#{hive_user}; 
        hdfs dfs -chown -R #{hive_user}:#{hive_group} /user/#{hive_user}
        """
        code_skipped: 1
        log: ctx.log
        stdout: ctx.log.stdout
        sterr: ctx.log.sterr
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_warehouse()
    do_warehouse = ->
      ctx.execute
        ssh: ssh
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
        hdfs dfs -mkdir -p /apps/#{hive_user};
        hdfs dfs -mkdir /apps/#{hive_user}/warehouse; 
        hdfs dfs -chown -R #{hive_user}:#{hive_group} /apps/#{hive_user}
        hdfs dfs -chmod -R 775 /apps/#{hive_user};
        """
        code_skipped: 3
        log: ctx.log
        stdout: ctx.log.stdout
        sterr: ctx.log.sterr
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_scratch()
    do_scratch = ->
      ctx.execute
        ssh: ssh
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
        hdfs dfs -mkdir /tmp 2>/dev/null;
        hdfs dfs -mkdir /tmp/scratch;
        hdfs dfs -chown #{hive_user}:#{hive_group} /tmp/scratch;
        hdfs dfs -chmod -R 777 /tmp/scratch;
        """
        code_skipped: 1
        log: ctx.log
        stdout: ctx.log.stdout
        sterr: ctx.log.sterr
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_end()
    do_end = ->
      next null, if modified then ctx.OK else ctx.PASS
    do_warehouse()

# https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Authorization#LanguageManualAuthorization-MetastoreServerSecurity
module.exports.push name: 'HDP Hive & HCat server # Metastore Security', callback: (ctx, next) ->
  {hive_conf_dir} = ctx.config.hdp
  hive_site =
    # authorization manager class name to be used in the metastore for authorization.
    # The user defined authorization class should implement interface
    # org.apache.hadoop.hive.ql.security.authorization.HiveMetastoreAuthorizationProvider.
    'hive.security.metastore.authorization.manager': 'org.apache.hadoop.hive.ql.security.authorization.DefaultHiveMetastoreAuthorizationProvider'
    # authenticator manager class name to be used in the metastore for authentication.
    # The user defined authenticator should implement interface 
    # org.apache.hadoop.hive.ql.security.HiveAuthenticationProvider.
    'hive.security.metastore.authenticator.manager': 'org.apache.hadoop.hive.ql.security.HadoopDefaultMetastoreAuthenticator'
    # pre-event listener classes to be loaded on the metastore side to run code
    # whenever databases, tables, and partitions are created, altered, or dropped.
    # Set to org.apache.hadoop.hive.ql.security.authorization.AuthorizationPreEventListener
    # if metastore-side authorization is desired.
    'hive.metastore.pre.event.listeners': ''
  ctx.hconfigure
    destination: "#{hive_conf_dir}/hive-site.xml"
    properties: hive_site
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

# todo: Securing the Hive MetaStore 
# http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html

# todo: Implement lock for Hive Server2
# http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

module.exports.push name: 'HDP Hive & HCat server # Start Metastore', callback: (ctx, next) ->
  lifecycle.hive_metastore_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat server # Start Server2', timeout: -1, callback: (ctx, next) ->
  lifecycle.hive_server2_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat server # Check', timeout: -1, callback: (ctx, next) ->
  # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
  # !connect jdbc:hive2://big3.big:10000/default;principal=hive/big3.big@ADALTAS.COM 
  next null, ctx.TODO






