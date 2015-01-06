
# Yarn ResourceManager Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./yarn_rm').configure

## Info Memory

    module.exports.push name: 'YARN RM # Info Memory', timeout: -1, label_true: 'INFO', callback: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/yarn-site.xml", (err, config) ->
        return next err if err
        ctx.report 'yarn.scheduler.minimum-allocation-mb', config['yarn.scheduler.minimum-allocation-mb']
        ctx.report 'yarn.scheduler.maximum-allocation-mb', config['yarn.scheduler.maximum-allocation-mb']
        next null, true

## Module Dependencies

    # mkcmd = require '../lib/mkcmd'
    properties = require '../lib/properties'



