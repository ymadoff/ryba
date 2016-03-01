
# Hadoop Yarn ResourceManager Info

## Info Memory

    module.exports = header: 'YARN RM # Info Memory', label_true: 'INFO', handler: (_, callback) ->
      {yarn} = @config.ryba
      properties.read @ssh, "#{yarn.rm.conf_dir}/yarn-site.xml", (err, config) ->
        return callback err if err
        @emit 'report',
          key: 'yarn.scheduler.minimum-allocation-mb'
          value: prink.filesize.from.megabytes config['yarn.scheduler.minimum-allocation-mb']
          raw: config['yarn.scheduler.minimum-allocation-mb']
          default: '1024'
          description: 'Lower memory allocated in MB for every container request.'
        @emit 'report',
          key: 'yarn.scheduler.maximum-allocation-mb'
          value: prink.filesize.from.megabytes config['yarn.scheduler.maximum-allocation-mb']
          raw: config['yarn.scheduler.maximum-allocation-mb']
          default: '8192'
          description: 'Higher memory allocated in MB for every container request.'
        callback null, true

## Dependencies

    properties = require '../../lib/properties'
    prink = require 'prink'
