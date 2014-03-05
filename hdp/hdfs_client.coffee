
hdfs_nn = require './hdfs_nn'
mkcmd = require './lib/mkcmd'

module.exports = []
module.exports.push 'phyla/hdp/core'

module.exports.push (ctx) ->
  require('./hdfs').configure ctx
  {realm} = ctx.config.krb5_client
  # Required
  ctx.config.hdp.hdfs_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
  ctx.config.hdp.hdfs_site['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{realm}"

module.exports.push name: 'HDP HDFS Client # Configuration', callback: (ctx, next) ->
  {hadoop_conf_dir, hdfs_site} = ctx.config.hdp
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/hdfs-site.xml"
    properties: hdfs_site
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS Client # HA', callback: (ctx, next) ->
  {hadoop_conf_dir} = ctx.config.hdp
  hdfs_site = hdfs_nn.ha_client_config ctx
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/hdfs-site.xml"
    properties: hdfs_site
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS Client # Check', timeout: -1, callback: (ctx, next) ->
  {hadoop_conf_dir, hdfs_site} = ctx.config.hdp
  port = hdfs_site['dfs.datanode.address']?.split('.')[1] or 1019
  # # DataNodes must all be started
  # datanodes = ctx.hosts_with_module 'phyla/hdp/hdfs_dn'
  # ctx.waitForConnection datanodes, port, (err) ->
  #   return next err if err
  # User "test" should be created
  ctx.waitForExecution "hdfs dfs -test -d /user/test", (err) ->
    return next err if err
    ctx.execute
      cmd: mkcmd.test ctx, """
      if hdfs dfs -test -f /user/test/hdfs_#{ctx.config.host}; then exit 2; fi
      hdfs dfs -touchz /user/test/hdfs_#{ctx.config.host}
      """
      code_skipped: 2
    , (err, executed, stdout) ->
      next err, if executed then ctx.OK else ctx.PASS


