

module.exports = []

module.exports.push 'histi/actions/hdp_core'

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_core').configure ctx
  {realm} = ctx.config.krb5_client
  srv2_host = ctx.servers(action: 'histi/actions/hdp_hive_server')[0]
  ctx.config.hdp.hive_conf_dir ?= '/etc/hive/conf'
  ctx.config.hdp.hive_site ?= {}
  ctx.config.hdp.hive_site['hive.metastore.uris'] ?= "thrift://#{srv2_host}:9083"
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
  ctx.config.hdp.hive_site['hive.server2.thrift.sasl.qop'] ?= 'auth'
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
 
