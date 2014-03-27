
{merge} = require 'mecano/lib/misc'
properties = require './lib/properties'
module.exports = []
module.exports.push 'phyla/bootstrap'

module.exports.push module.exports.configure = (ctx) ->
  require('./yarn').configure ctx

module.exports.push name: 'HDP YARN # Configuration', callback: (ctx, next) ->
  { hadoop_conf_dir, yarn_user, yarn_group, yarn } = ctx.config.hdp
  properties.read "#{__dirname}/files/core_hadoop/yarn-site.xml", (err, yarn_default) ->
    yarn_site = merge {}, yarn_default, yarn
    config = {}
    for k, v of yarn_site
      continue if k isnt 'yarn.application.classpath' and k.indexOf('yarn.resourcemanager') is -1
      config[k] = v
    ctx.hconfigure
      destination: "#{hadoop_conf_dir}/yarn-site.xml"
      properties: config
      merge: true
      uid: yarn_user
      gid: yarn_group
    , (err, configured) ->
      return next err, if configured then ctx.OK else ctx.PASS 