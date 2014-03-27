
module.exports = []
module.exports.push 'phyla/bootstrap'
module.exports.push 'phyla/utils/java'
module.exports.push 'phyla/hdp/core'
module.exports.push 'phyla/hdp/hdfs_client'

module.exports.push module.exports.configure = (ctx) ->
  return if ctx.hive__configured
  ctx.hive__configured = true
  require('./core').configure ctx
  {realm} = ctx.config.krb5_client
  {static_host} = ctx.config.hdp
  ctx.config.hdp.hive_conf_dir ?= '/etc/hive/conf'
  metastore_host = ctx.config.hdp.hive_metastore_host ?= ctx.host_with_module 'phyla/hdp/hive_server'
  ctx.config.hdp.hive_metastore_port ?= 9083
  ctx.config.hdp.hive_metastore_timeout ?= 20000 # 20s
  ctx.config.hdp.hive_server2_host ?= ctx.host_with_module 'phyla/hdp/hive_server'
  ctx.config.hdp.hive_server2_port ?= 10000
  ctx.config.hdp.hive_server2_timeout ?= 20000 # 20s
  ctx.config.hdp.hive_site ?= {}
  ctx.config.hdp.hive_user ?= 'hive'
  ctx.config.hdp.hive_group ?= 'hive'
  ctx.config.hdp.hive_site['hive.metastore.uris'] ?= "thrift://#{metastore_host}:9083"
  # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2)
  # , by setting following params to true
  ctx.config.hdp.hive_site['fs.hdfs.impl.disable.cache'] ?= 'false'
  ctx.config.hdp.hive_site['fs.file.impl.disable.cache'] ?= 'false'
  # TODO: encryption is only with Kerberos, need to check first
  # http://hortonworks.com/blog/encrypting-communication-between-hadoop-and-your-analytics-tools/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+hortonworks%2Ffeed+%28Hortonworks+on+Hadoop%29
  ctx.config.hdp.hive_site['hive.server2.thrift.sasl.qop'] ?= 'auth'
  # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap14-2-3.html#rmp-chap14-2-3-5
  # If true, the metastore thrift interface will be secured with
  # SASL. Clients must authenticate with Kerberos.
  ctx.config.hdp.hive_site['hive.metastore.sasl.enabled'] ?= 'true'
  # The path to the Kerberos Keytab file containing the metastore
  # thrift server's service principal.
  ctx.config.hdp.hive_site['hive.metastore.kerberos.keytab.file'] ?= '/etc/hive/conf/hive.service.keytab'
  # The service principal for the metastore thrift server. The
  # special string _HOST will be replaced automatically with the correct  hostname.
  ctx.config.hdp.hive_site['hive.metastore.kerberos.principal'] ?= "hive/#{static_host}@#{realm}"
  ctx.config.hdp.hive_site['hive.metastore.cache.pinobjtypes'] ?= 'Table,Database,Type,FieldSchema,Order'
  # https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2
  # Authentication type
  ctx.config.hdp.hive_site['hive.server2.authentication'] ?= 'KERBEROS'
  # The keytab for the HiveServer2 service principal
  # 'hive.server2.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
  ctx.config.hdp.hive_site['hive.server2.authentication.kerberos.keytab'] ?= '/etc/hive/conf/hive.service.keytab'
  # The service principal for the HiveServer2. If _HOST
  # is used as the hostname portion, it will be replaced.
  # with the actual hostname of the running instance.
  # 'hive.server2.authentication.kerberos.principal': "hcat/#{ctx.config.host}@#{realm}"
  ctx.config.hdp.hive_site['hive.server2.authentication.kerberos.principal'] ?= "hive/#{static_host}@#{realm}"

###
Install
-------
Instructions to [install the Hive and HCatalog RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3/bk_installing_manually_book/content/rpm-chap6-1.html)
###
module.exports.push name: 'HDP Hive & HCat # Install', timeout: -1, callback: (ctx, next) ->
  modified = false
  {hive_conf_dir} = ctx.config.hdp
  do_hive = ->
    ctx.log 'Install the hive package'
    ctx.service name: 'hive', (err, serviced) ->
      return next err if err
      modified = true if serviced
      ctx.log 'Copy hive-env.sh'
      conf_files = "#{__dirname}/files/hive"
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
 
