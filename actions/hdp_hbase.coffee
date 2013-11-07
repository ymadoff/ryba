
hproperties = require './hadoop/lib/properties'
module.exports = []

module.exports.push 'histi/actions/yum'

module.exports.push module.exports.configure = (ctx) ->
  require('./hdp_core').configure ctx
  require('./krb5_client').configure ctx
  {realm} = ctx.config.krb5_client
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  zookeeper_hosts = (ctx.config.servers.filter (s) -> s.hdp?.zookeeper).map( (s) -> s.host ).join ','
  ctx.config.hdp ?= {}
  ctx.config.hdp.hbase_user ?= 'hbase'
  ctx.config.hdp.hbase_log_dir ?= '/var/log/hbase'
  ctx.config.hdp.hbase_pid_dir ?= '/var/run/hbase'
  ctx.config.hdp.hbase_site ?= {}
  # The mode the cluster will be in. Possible values are
  # false: standalone and pseudo-distributed setups with managed Zookeeper
  # true: fully-distributed with unmanaged Zookeeper Quorum (see hbase-env.sh)
  ctx.config.hdp.hbase_site['hbase.cluster.distributed'] = 'true'
  # Enter the HBase NameNode server hostname
  ctx.config.hdp.hbase_site['hbase.rootdir'] ?= "hdfs://#{namenode}:8020/apps/hbase/data"
  # The bind address for the HBase Master web UI, [Official doc](http://hbase.apache.org/configuration.html)
  # Enter the HBase Master server hostname, [HDP DOC](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap9-3.html)
  ctx.config.hdp.hbase_site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
  # Comma separated list of Zookeeper servers (match to
  # what is specified in zoo.cfg but without portnumbers)
  ctx.config.hdp.hbase_site['hbase.zookeeper.quorum'] ?= "#{zookeeper_hosts}"
  ctx.config.hdp.hbase_site['hbase.master.keytab.file'] ?= '/etc/security/keytabs/hm.service.keytab'
  ctx.config.hdp.hbase_site['hbase.master.kerberos.principal'] ?= "hm/_HOST@#{realm}"
  ctx.config.hdp.hbase_site['hbase.regionserver.keytab.file'] ?= '/etc/security/keytabs/rs.service.keytab'
  ctx.config.hdp.hbase_site['hbase.regionserver.kerberos.principal'] ?= "rs/_HOST@#{realm}"
  ctx.config.hdp.hbase_site['hbase.superuser'] ?= 'hbase'
  ctx.config.hdp.hbase_site['hbase.coprocessor.region.classes'] ?= ''
  ctx.config.hdp.hbase_site['hbase.coprocessor.master.classes'] ?= ''
  # Short-circuit are true but socket.path isnt defined for hbase, only for hdfs, see http://osdir.com/ml/hbase-user-hadoop-apache/2013-03/msg00007.html
  ctx.config.hdp.hbase_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

###
Install
-------
Instructions to [install the HBase RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap9-1.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP HBase # Install'
  @timeout -1
  ctx.service name: 'hbase', (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hbase_user, hadoop_group} = ctx.config.hdp
  @name 'HDP HBase # Users & Groups'
  # User must be created for HBase master and regionserver
  ctx.execute
    cmd: "useradd #{hbase_user} -r -g #{hadoop_group} -d /var/run/#{hbase_user} -s /bin/bash -c \"HBase\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hadoop_group, hbase_user, hbase_pid_dir, hbase_log_dir} = ctx.config.hdp
  @name 'HDP HBase # Layout'
  ctx.mkdir [
    destination: hbase_pid_dir
    uid: hbase_user
    gid: hadoop_group
    mode: '755'
  ,
    destination: hbase_log_dir
    uid: hbase_user
    gid: hadoop_group
    mode: '755'
  ], (err, modified) ->
    next err, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP HBase # Configure'
  {hbase_site} = ctx.config.hdp
  ctx.log 'Configure hbase-site.xml'
  ctx.hconfigure
    destination: '/etc/hbase/conf/hbase-site.xml'
    default: "#{__dirname}/hdp/hbase/hbase-site.xml"
    local_default: true
    properties: hbase_site
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP HBase # RegionServer'
  regionservers = (ctx.config.servers.filter (s) -> s.hdp?.hbase_regionserver).join('\n')
  {hbase_user} = ctx.config.hdp
  ctx.write
    content: regionservers
    destination: '/etc/hbase/conf/regionservers'
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS






