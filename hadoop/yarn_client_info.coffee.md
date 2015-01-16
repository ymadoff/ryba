
# Yarn ResourceManager Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./yarn_client').configure

## Info Memory

    module.exports.push name: 'YARN Client # Info Memory', timeout: -1, label_true: 'INFO', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/yarn-site.xml", (err, config) ->
        return next err if err
        ctx.report 'yarn.app.mapreduce.am.resource.mb', config['yarn.app.mapreduce.am.resource.mb']
        ctx.report 'yarn.app.mapreduce.am.command-opts', config['yarn.app.mapreduce.am.command-opts']
        next null, true

## Module Dependencies

    # mkcmd = require '../lib/mkcmd'
    properties = require '../lib/properties'



