
lifecycle = require './lib/lifecycle'
mkcmd = require './lib/mkcmd'
module.exports = []

module.exports.push 'histi/hdp/hdfs'

module.exports.push (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP HDFS JN # Configure', callback: (ctx, next) ->
  {hadoop_conf_dir} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  hdfs_site = {}
  hdfs_site['dfs.journalnode.edits.dir'] = '/var/run/hadoop-hdfs/journalnode_edit_dir'
  # hdfs_site['dfs.journalnode.http-address'] = '0.0.0.0:8480'
  hdfs_site['dfs.journalnode.kerberos.internal.spnego.principal'] = "HTTP/_HOST@#{realm}"
  hdfs_site['dfs.journalnode.kerberos.principal'] = "HTTP/_HOST@#{realm}"
  hdfs_site['dfs.journalnode.keytab.file '] = '/etc/security/keytabs/spnego.service.keytab'
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/hdfs-site.xml"
    properties: hdfs_site
    merge: true
  , (err, configured) ->
    return next err if err
    next null, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS JN # Start', callback: (ctx, next) ->
  lifecycle.jn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS
