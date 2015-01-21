
# Hadoop MapRed Client Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./mapred_client').configure

## Info Memory

http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html

    module.exports.push name: 'MapRed Client # Info Memory', timeout: -1, label_true: 'INFO', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/mapred-site.xml", (err, config) ->
        return next err if err
        ctx.emit 'report', 
          key: 'mapreduce.map.memory.mb'
          value: config['mapreduce.map.memory.mb']
          default: 1536
          description: 'Larger resource limit for maps.'
        ctx.emit 'report',
          key: 'mapreduce.map.java.opts'
          value: config['mapreduce.map.java.opts']
          default: '-Xmx1024M'
          description: 'Larger heap-size for child jvms of maps.'
        ctx.emit 'report',
          key: 'mapreduce.reduce.memory.mb'
          value: config['mapreduce.reduce.memory.mb']
          default: 3072
          description: 'Larger resource limit for reduces.'
        ctx.emit 'report',
          key: 'mapreduce.reduce.java.opts'
          value: config['mapreduce.reduce.java.opts']
          default: '-Xmx2560M'
          description: 'Larger heap-size for child jvms of reduces.'
        ctx.emit 'report',
          key: 'mapreduce.task.io.sort.mb'
          value: config['mapreduce.task.io.sort.mb']
          default: 512
          description: 'Higher memory-limit while sorting data for efficiency.'
        ctx.emit 'report',
          key: 'mapreduce.task.io.sort.factor'
          value: config['mapreduce.task.io.sort.factor']
          default: 100
          description: 'More streams merged at once while sorting files.'
        ctx.emit 'report',
          key: 'mapreduce.reduce.shuffle.parallelcopies'
          value: config['mapreduce.reduce.shuffle.parallelcopies']
          default: 50
          description: 'Higher number of parallel copies run by reduces to fetch outputs from very large number of maps.'
        next null, true

## Module Dependencies

    # mkcmd = require '../lib/mkcmd'
    properties = require '../lib/properties'



