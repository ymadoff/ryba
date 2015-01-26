
# Hadoop Yarn ResourceManager Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./yarn_rm').configure

## Info Memory

    module.exports.push name: 'YARN RM # Info Memory', timeout: -1, label_true: 'INFO', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/yarn-site.xml", (err, config) ->
        return next err if err
        ctx.emit 'report',
          key: 'yarn.scheduler.minimum-allocation-mb'
          value: prink.filesize.from.megabytes config['yarn.scheduler.minimum-allocation-mb']
          raw: config['yarn.scheduler.minimum-allocation-mb']
          default: '1024'
          description: 'Lower memory allocated in MB for every container request.'
        ctx.emit 'report',
          key: 'yarn.scheduler.maximum-allocation-mb'
          value: prink.filesize.from.megabytes config['yarn.scheduler.maximum-allocation-mb']
          raw: config['yarn.scheduler.maximum-allocation-mb']
          default: '8192'
          description: 'Higher memory allocated in MB for every container request.'
        next null, true

## Module Dependencies

    properties = require '../lib/properties'
    prink = require 'prink'



