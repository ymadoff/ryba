
path = require 'path'
mkcmd = require './hdp/mkcmd'
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push 'histi/actions/mysql_client'

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hive_client').configure ctx
  require('./krb5_client').configure ctx
  {realm} = ctx.config.krb5_client
  # Define Users and Groups
  ctx.config.hdp.webhcat_user ?= 'webhcat'
  ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
  ctx.config.hdp.hive_pid_dir ?= '/var/run/hive'
  ctx.config.hdp.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
  ctx.config.hdp.webhcat_log_dir ?= '/var/log/webhcat/webhcat'
  ctx.config.hdp.webhcat_pid_dir ?= '/var/run/webhcat'
  ctx.config.hdp.hive_libs ?= []
  ctx.config.hdp.hive_user ?= 'hive'
  ctx.config.hdp.hive_site ?= {}
  # ctx.config.hdp.hive_site['hive.metastore.uris'] ?= ''
  # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2)
  # , by setting following params to true
  ctx.config.hdp.hive_site['fs.hdfs.impl.disable.cache'] ?= 'false'
  ctx.config.hdp.hive_site['fs.file.impl.disable.cache'] ?= 'false'
  # TODO: encryption is only with Kerberos, need to check first
  # http://hortonworks.com/blog/encrypting-communication-between-hadoop-and-your-analytics-tools/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+hortonworks%2Ffeed+%28Hortonworks+on+Hadoop%29
  ctx.config.hdp.hive_site['hive.server2.thrift.sasl.qop'] ?= 'auth-conf'
  # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap14-2-3.html#rmp-chap14-2-3-5
  # If true, the metastore thrift interface will be secured with
  # SASL. Clients must authenticate with Kerberos.
  ctx.config.hdp.hive_site['hive.metastore.sasl.enabled'] ?= 'true'
  # The path to the Kerberos Keytab file containing the metastore
  # thrift server's service principal.
  ctx.config.hdp.hive_site['hive.metastore.kerberos.keytab.file'] ?= '/etc/security/keytabs/hive.service.keytab'
  # The service principal for the metastore thrift server. The
  # special string _HOST will be replaced automatically with the correct  hostname.
  ctx.config.hdp.hive_site['hive.metastore.kerberos.principal'] ?= "hive/_HOST@#{realm}"
  ctx.config.hdp.hive_site['hive.metastore.cache.pinobjtypes'] ?= 'Table,Database,Type,FieldSchema,Order'
  # https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2
  # Authentication type
  ctx.config.hdp.hive_site['hive.server2.authentication'] ?= 'KERBEROS'
  # The keytab for the HiveServer2 service principal
  # 'hive.server2.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
  ctx.config.hdp.hive_site['hive.server2.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/hive.service.keytab'
  # The service principal for the HiveServer2. If _HOST
  # is used as the hostname portion, it will be replaced
  # with the actual hostname of the running instance.
  # 'hive.server2.authentication.kerberos.principal': "hcat/#{ctx.config.host}@#{realm}"
  ctx.config.hdp.hive_site['hive.server2.authentication.kerberos.principal'] ?= "hive/_HOST@#{realm}"

module.exports.push (ctx, next) ->
  @name 'HDP Hive Server # Configure'
  {realm} = ctx.config.krb5_client
  {hive_site} = ctx.config.hdp
  ctx.hconfigure
    destination: '/etc/hive/conf/hive-site.xml'
    default: "#{__dirname}/hdp/hive/hive-site.xml"
    local_default: true
    properties: hive_site
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

#http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
#http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode
module.exports.push (ctx, next) ->
  @name "HDP Hive # Users"
  {hive_user, hadoop_group, webhcat_user} = ctx.config.hdp
  cmd = (cmd) ->
    cmd: cmd
    code: 0
    code_skipped: 9
  cmds = []
  cmds.push cmd "groupadd hadoop"
  cmds.push cmd "useradd #{hive_user} -c \"Used by Hadoop Hive service\" -r -M -g #{hadoop_group}"
  cmds.push cmd "useradd #{webhcat_user} -c \"Used by Hadoop HCatalog/WebHCat service\" -r -M -g #{hadoop_group}" if ctx.config.hdp.hcatalog_server or ctx.config.hdp.webhcat
  ctx.execute parallel: 1, cmds, (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hive_libs} = ctx.config.hdp
  return next() unless hive_libs.length
  @name 'HDP Hive & HCatalog # Libs'
  uploads = for lib in hive_libs
    source: lib
    destination: "/usr/lib/hive/lib/#{path.basename lib}"
  ctx.upload uploads, (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Layout'
  {hive_log_dir, hive_user, hadoop_group, mode} = ctx.config.hdp
  ctx.mkdir
    destination: hive_log_dir
    uid: hive_user
    gid: hadoop_group
    mode: 0o0755
  , (err, modified) ->
    return next err, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & Kerberos Keytabs'
  {hive_user, hadoop_group} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc
    principal: "hive/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/hive.service.keytab"
    uid: hive_user
    gid: hadoop_group
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

module.exports.push (ctx, next) ->
  {hdfs_user, hive_user, hadoop_group} = ctx.config.hdp
  @name 'HDP Hive # Layout'
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
        hadoop fs -mkdir /apps/#{hive_user};
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
        if hadoop fs -ls /tmp &> /dev/null; then exit 1; fi
        hadoop fs -mkdir /tmp;
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
  @name 'HDP Hive # Check'
  # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
  # !connect jdbc:hive2://big3.big:10000/default;principal=hive/big3.big@ADALTAS.COM 
  next null, ctx.TODO






