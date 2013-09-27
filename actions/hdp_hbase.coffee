
hdp = require './hdp'
module.exports = []
hproperties = require './hadoop/lib/properties'

module.exports.push (ctx) ->
  hdp.configure ctx
  namenode = (ctx.config.servers.filter (s) -> s.hdp?.namenode)[0].host
  zookeeper_hosts = (ctx.config.servers.filter (s) -> s.hdp?.zookeeper).map( (s) -> s.host ).join ','
  ctx.config.hdp_hbase ?= {}
  ctx.config.hdp_hbase.user ?= 'hbase'
  ctx.config.hdp_hbase.log_dir ?= '/var/log/hbase'
  ctx.config.hdp_hbase.pid_dir ?= '/var/run/hbase'
  ctx.config.hdp_hbase.hbase_site ?= {}
  # Enter the HBase NameNode server hostname
  ctx.config.hdp_hbase.hbase_site['hbase.rootdir'] ?= "hdfs://#{namenode}:8020/apps/hbase/data"
  # The bind address for the HBase Master web UI.
  ctx.config.hdp_hbase.hbase_site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
  # Comma separated list of Zookeeper servers (match to
  # what is specified in zoo.cfg but without portnumbers)
  ctx.config.hdp_hbase.hbase_site['hbase.zookeeper.quorum'] ?= "#{zookeeper_hosts}"

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
  {hadoop_group} = ctx.config.hdp
  {user} = ctx.config.hdp_hbase
  @name 'HDP HBase # Users & Groups'
  # User must be created for HBase master and regionserver
  ctx.execute
    cmd: "useradd #{user} -c \"HBase\" -r -g #{hadoop_group} -d /var/run/#{user}"
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hadoop_group} = ctx.config.hdp
  {user, pid_dir, log_dir} = ctx.config.hdp_hbase
  @name 'HDP HBase # Layout'
  ctx.mkdir [
    destination: pid_dir
    uid: user
    gid: hadoop_group
    mode: '755'
  ,
    destination: log_dir
    uid: user
    gid: hadoop_group
    mode: '755'
  ], (err, modified) ->
    next err, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP HBase # Configure'
  {hbase_site} = ctx.config.hdp_hbase
  ctx.log 'Configure hbase-site.xml'
  ctx.hconfigure
    destination: '/etc/hbase/conf/hbase-site.xml'
    default: "#{__dirname}/hdp/hbase/hbase-site.xml"
    local_default: true
    properties: hbase_site
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS








