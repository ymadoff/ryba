
path = require 'path'
hdp = require './hdp'
module.exports = []

module.exports.push 'histi/actions/mysql_client'

###
Example of a minimal client configuration:
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>hive.metastore.kerberos.keytab.file</name>
    <value>/etc/security/keytabs/hive.service.keytab</value>
  </property>
  <property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/_HOST@EDF.FR</value>
  </property>
  <property>
    <name>hive.metastore.sasl.enabled</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://big3.big:9083</value>
  </property>
</configuration>
###

module.exports.push (ctx) ->
  ctx.config.hdp_hive ?= {}
  ctx.config.hdp.hive_conf_dir ?= '/etc/hive/conf'
  ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
  ctx.config.hdp.hive_pid_dir ?= '/var/run/hive'
  ctx.config.hdp_hive.libs ?= []
  ctx.config.hdp_hive.log_dir ?= '/var/log/hive'
  ctx.config.hdp_hive.user ?= 'hive'
  ctx.config.hdp_hive.group ?= 'hadoop'
  ctx.config.hdp_hive.mode ?= 0o0755
  ctx.config.hdp_hive.hive_site ?= {}
  # Overwrite hdp properties with unworkable values
  # Note, next 3 lines cause failure when hdp_krb5 is run independently
  # ctx.config.hdp_hive.hive_site['hive.metastore.kerberos.principal'] ?= ''
  # ctx.config.hdp_hive.hive_site['hive.server2.authentication.kerberos.principal'] ?= ''
  # ctx.config.hdp_hive.hive_site['hive.metastore.uris'] ?= ''
  # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/Hive/setting-up-hiveserver2.html)
  # , by setting following params to true
  ctx.config.hdp_hive.hive_site['fs.hdfs.impl.disable.cache'] ?= 'true'
  ctx.config.hdp_hive.hive_site['fs.file.impl.disable.cache'] ?= 'true'
  hdp.configure ctx

###
Install
-------
Instructions to [install the Hive and HCatalog RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap6-1.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Install'
  @timeout -1
  modified = true
  do_hive = ->
    ctx.log 'Install the hive package'
    ctx.service name: 'hive', (err, serviced) ->
      return next err if err
      modified if serviced
      ctx.log 'Copy hive-env.sh and hive-site.xml'
      conf_files = "#{__dirname}/hdp/hive"
      ctx.upload
        source: "#{conf_files}/hive-env.sh"
        destination: "/etc/hive/conf/hive-env.sh"
      , (err, copied) ->
        return next err if err
        do_hcatalog()
  do_hcatalog = ->
    ctx.log 'Install the hcatalog package'
    ctx.service name: 'hcatalog', (err, serviced) ->
      return next err if err
      modified if serviced
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_hive()

module.exports.push (ctx, next) ->
  {libs} = ctx.config.hdp_hive
  return next() unless libs.length
  @name 'HDP Hive & HCatalog # Libs'
  uploads = for lib in libs
    source: lib
    destination: "/usr/lib/hive/lib/#{path.basename lib}"
  ctx.upload uploads, (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Layout'
  {log_dir, user, group, mode} = ctx.config.hdp_hive
  ctx.mkdir
    destination: log_dir
    uid: user
    gid: group
    mode: mode
  , (err, modified) ->
    return next err, if modified then ctx.OK else ctx.PASS

###
Configure
---------

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Configure'
  {hive_site} = ctx.config.hdp_hive
  ctx.hconfigure
    destination: '/etc/hive/conf/hive-site.xml'
    default: "#{__dirname}/hdp/hive/hive-site.xml"
    local_default: true
    properties: hive_site
  , (err, configured) ->
    return next err, if configured then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Driver'
  ctx.link
    source: '/usr/share/java/mysql-connector-java.jar'
    destination: '/usr/lib/hive/lib/mysql-connector-java.jar'
  , (err, configured) ->
    return next err, if configured then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hdfs_user} = ctx.config.hdp
  {user} = ctx.config.hdp_hive
  @name 'HDP Hive # Layout'
  kerberos = true
  modified = false
  do_warehouse = ->
    cmd = """
    if hadoop fs -ls /user/#{user}/warehouse &>/dev/null; then 
      exit 1;
    else
      hadoop fs -mkdir /user/#{user}; 
      hadoop fs -mkdir /user/#{user}/warehouse; 
      hadoop fs -chown -R #{user} /user/#{user}; hadoop fs -chmod g+w /user/#{user}/warehouse;
    fi'
    """
    unless kerberos
      ctx.execute
        cmd: "su -l #{hdfs_user} -c \"#{cmd}\""
      , (err, executed) ->
    else
      ctx.execute
        cmd: """
        kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {
          #{cmd}
        }
        """
        code_skipped: 1
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_temp()
  do_temp = ->
    cmd = """
    if hadoop fs -ls /tmp &> /dev/null;then
      exit 1;
    else
      hadoop fs -mkdir /tmp;
      hadoop fs -chmod g+w /tmp;
    fi'
    """
    unless kerberos
      ctx.execute
        cmd: "su -l #{hdfs_user} -c \"#{cmd}\""
      , (err, executed) ->
    else
      ctx.execute
        cmd: """
        kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs && {
          #{cmd}
        }
        """
        code_skipped: 1
      , (err, executed, stdout) ->
        return next err if err
        modified = true if executed
        do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_warehouse()








