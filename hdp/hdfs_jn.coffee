
lifecycle = require './lib/lifecycle'
mkcmd = require './lib/mkcmd'
module.exports = []

module.exports.push 'phyla/hdp/hdfs'

module.exports.push module.exports.configure = (ctx) ->
  require('./hdfs').configure ctx

module.exports.push name: 'HDP HDFS JN # Layout', callback: (ctx, next) ->
  {hdfs_site, hadoop_conf_dir} = ctx.config.hdp
  modified = false
  do_mkdir = ->
    ctx.mkdir
      destination: hdfs_site['dfs.journalnode.edits.dir']
      uid: 'hdfs'
      gid: 'hadoop'
    , (err, created) ->
      return next err if err
      modified = true if created
      do_config()
  do_config = ->
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/hdfs-site.xml"
      properties: hdfs_site
      merge: true
    , (err, configured) ->
      return next err if err
      modified = true if configured
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_mkdir()

module.exports.push name: 'HDP HDFS JN # Kerberos', callback: (ctx, next) ->
  {hadoop_conf_dir} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  hdfs_site = {}
  # hdfs_site['dfs.journalnode.http-address'] = '0.0.0.0:8480'
  hdfs_site['dfs.journalnode.kerberos.internal.spnego.principal'] = "HTTP/_HOST@#{realm}"
  hdfs_site['dfs.journalnode.kerberos.principal'] = "HTTP/_HOST@#{realm}"
  hdfs_site['dfs.journalnode.keytab.file '] = '/etc/security/keytabs/spnego.service.keytab'
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/hdfs-site.xml"
    properties: hdfs_site
    merge: true
  , (err, configured) ->
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP HDFS JN # Start', callback: (ctx, next) ->
  lifecycle.jn_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS
