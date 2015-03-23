
# Yarn ResourceManager Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./index').configure

## Info Memory

    module.exports.push name: 'YARN Client # Info Memory', timeout: -1, label_true: 'INFO', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/yarn-site.xml", (err, config) ->
        return next err if err
        ctx.emit 'report',
          key: 'yarn.app.mapreduce.am.resource.mb'
          value:  prink.filesize.from.megabytes config['yarn.app.mapreduce.am.resource.mb']
          raw: config['yarn.app.mapreduce.am.resource.mb']
          default: '1536'
          description: 'Memory needed by the MR AppMaster (recommandation: 2 * RAM-per-Container).'
        ctx.emit 'report',
          key: 'yarn.app.mapreduce.am.command-opts'
          value: config['yarn.app.mapreduce.am.command-opts']
          default: '-Xmx1024m'
          description: 'Java opts for the MR App Master (recommandation: 0.8 * 2 * RAM-per-Container).'
        next null, true

## Module Dependencies

    # mkcmd = require '../../lib/mkcmd'
    properties = require '../../lib/properties'
    prink = require 'prink'



