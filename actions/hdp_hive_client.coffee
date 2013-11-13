
path = require 'path'
mkcmd = require './hdp/mkcmd'
lifecycle = require './hdp/lifecycle'

module.exports = []
module.exports.push 'histi/actions/hdp_core'

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
  {realm} = ctx.config.krb5_client
  ctx.config.hdp.hive_conf_dir ?= '/etc/hive/conf'
  ctx.config.hdp.hive_site ?= {}
  # Overwrite hdp properties with unworkable values
  # Note, next 3 lines cause failure when hdp_krb5 is run independently
  # ctx.config.hdp.hive_site['hive.metastore.kerberos.principal'] ?= ''
  # ctx.config.hdp.hive_site['hive.server2.authentication.kerberos.principal'] ?= ''
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

###
Install
-------
Instructions to [install the Hive and HCatalog RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap6-1.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat client # Install'
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
  @name 'HDP Hive & HCat client # Configure'
  {hive_site, hive_user, hadoop_group, hive_conf_dir} = ctx.config.hdp
  ctx.hconfigure
    destination: "#{hive_conf_dir}/hive-site.xml"
    default: "#{__dirname}/hdp/hive/hive-site.xml"
    local_default: true
    properties: hive_site
  , (err, configured) ->
    return next err if err
    ctx.execute
      cmd: """
      chown -R #{hive_user}:#{hadoop_group} #{hive_conf_dir}
      chmod -R 755 #{hive_conf_dir}
      """
    , (err) ->
      next err, if configured then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat client # Driver'
  ctx.link
    source: '/usr/share/java/mysql-connector-java.jar'
    destination: '/usr/lib/hive/lib/mysql-connector-java.jar'
  , (err, configured) ->
    return next err, if configured then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat client # Kerberos Keytabs'
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


