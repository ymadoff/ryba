
path = require 'path'
mkcmd = require './hdp/mkcmd'
lifecycle = require './hdp/lifecycle'
module.exports = []

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

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_core').configure ctx
  require('./krb5_client').configure ctx
  ctx.config.hdp.hive_conf_dir ?= '/etc/hive/conf'
  ctx.config.hdp.hive_site ?= {}
  # Overwrite hdp properties with unworkable values
  # Note, next 3 lines cause failure when hdp_krb5 is run independently
  # ctx.config.hdp.hive_site['hive.metastore.kerberos.principal'] ?= ''
  # ctx.config.hdp.hive_site['hive.server2.authentication.kerberos.principal'] ?= ''
  # ctx.config.hdp.hive_site['hive.metastore.uris'] ?= ''
  # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/Hive/setting-up-hiveserver2.html)
  # , by setting following params to true
  ctx.config.hdp.hive_site['fs.hdfs.impl.disable.cache'] ?= 'true'
  ctx.config.hdp.hive_site['fs.file.impl.disable.cache'] ?= 'true'
  # TODO: encryption is only with Kerberos, need to check first
  # http://hortonworks.com/blog/encrypting-communication-between-hadoop-and-your-analytics-tools/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+hortonworks%2Ffeed+%28Hortonworks+on+Hadoop%29
  ctx.config.hdp.hive_site['hive.server2.thrift.sasl.qop'] ?= 'auth-conf'

###
Install
-------
Instructions to [install the Hive and HCatalog RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap6-1.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Install'
  @timeout -1
  modified = false
  {hive_conf_dir} = ctx.config.hdp
  do_hive = ->
    ctx.log 'Install the hive package'
    ctx.service name: 'hive', (err, serviced) ->
      return next err if err
      modified = true if serviced
      ctx.log 'Copy hive-env.sh'
      conf_files = "#{__dirname}/hdp/hive"
      ctx.upload
        source: "#{conf_files}/hive-env.sh"
        destination: "#{hive_conf_dir}/hive-env.sh"
      , (err, copied) ->
        return next err if err
        do_hcatalog()
  do_hcatalog = ->
    ctx.log 'Install the hcatalog package'
    ctx.service name: 'hcatalog', (err, serviced) ->
      return next err if err
      modified = true if serviced
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_hive()

###
Configure
---------

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Configure'
  {hive_site, hive_conf_dir} = ctx.config.hdp
  ctx.hconfigure
    destination: "#{hive_conf_dir}/hive-site.xml"
    default: "#{__dirname}/hdp/hive/hive-site.xml"
    local_default: true
    properties: hive_site
  , (err, configured) ->
    return next err, ctx.PASS if err or not configured
    # return next err, if configured then ctx.OK else ctx.PASS
    lifecycle.hive_restart ctx, (err) ->
      return next err, ctx.OK

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCatalog # Driver'
  ctx.link
    source: '/usr/share/java/mysql-connector-java.jar'
    destination: '/usr/lib/hive/lib/mysql-connector-java.jar'
  , (err, configured) ->
    return next err, if configured then ctx.OK else ctx.PASS