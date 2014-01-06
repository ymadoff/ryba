
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
  require('./hdp_hdfs').configure ctx
  require('./hdp_hive_').configure ctx

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
    merge: true
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
  @name 'HDP Hive & HCat client # Kerberos'
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
  @name 'HDP Hive & HCat client # Logs'
  ctx.write [
    source: "#{__dirname}/hdp/hive/hive-exec-log4j.properties.template"
    local_source: true
    destination: '/etc/hive/conf/hive-exec-log4j.properties'
  ,
    source: "#{__dirname}/hdp/hive/hive-log4j.properties.template"
    local_source: true
    destination: '/etc/hive/conf/hive-log4j.properties'
  ], (err, written) ->
    return next err, if written then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP Hive & HCat client # Check'
  ctx.execute
    cmd: mkcmd.test ctx, """
    if hdfs dfs -test -d /user/test/hive_#{ctx.config.host}/check_hive_tb; then exit 2; fi
    hive -e "
      CREATE DATABASE IF NOT EXISTS check_hive_db  LOCATION '/user/test/hive_#{ctx.config.host}'; \\
      USE check_hive_db; \\
      CREATE TABLE IF NOT EXISTS check_hive_tb(col1 STRING, col2 INT);" || exit 1
    echo "a,1\\nb,2\\nc,3" > /tmp/check_hive;
    hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_hive_tb
    hdfs dfs -put /tmp/check_hive /user/test/hive_#{ctx.config.host}/check_hive_tb/data || exit 1
    hive -e "SELECT SUM(col2) FROM check_hive_db.check_hive_tb;" || exit 1
    hive -e "DROP TABLE check_hive_db.check_hive_tb; DROP DATABASE check_hive_db;" || exit 1
    rm -rf /tmp/check_hive
    hdfs dfs -touchz /user/test/hive_#{ctx.config.host}
    """
    code_skipped: 2
  , (err, executed, stdout) ->
    return next err, if executed then ctx.OK else ctx.PASS


