
# Yarn ResourceManager Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./yarn_nm').configure

## Info Memory

    module.exports.push name: 'YARN NodeManager # Info Memory', timeout: -1, label_true: 'INFO', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/yarn-site.xml", (err, config) ->
        return next err if err
        ctx.emit 'report',
          key: 'yarn.nodemanager.resource.memory-mb'
          value:  prink.filesize.from.megabytes config['yarn.nodemanager.resource.memory-mb']
          raw: config['yarn.nodemanager.resource.memory-mb']
          default: '8192'
          description: 'Physical memory in MB allocated for containers.'
        ctx.emit 'report',
          key: 'yarn.nodemanager.vmem-pmem-ratio'
          value: config['yarn.nodemanager.vmem-pmem-ratio']
          default: '2.1'
          description: 'Ratio between virtual memory to physical memory.'
        next null, true

## Module Dependencies

    # mkcmd = require '../lib/mkcmd'
    properties = require '../lib/properties'
    prink = require 'prink'


