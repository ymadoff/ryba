
# MapRed Client Info

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/report'
    module.exports.push require('./mapred_client').configure

## Info Memory

    module.exports.push name: 'Hadoop MapRed Client # Info Memory', timeout: -1, label_true: 'INFO', callback: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      properties.read ctx.ssh, "#{hadoop_conf_dir}/mapred-site.xml", (err, config) ->
        return next err if err
        ctx.report 'mapreduce.map.memory.mb', config['mapreduce.map.memory.mb']
        ctx.report 'mapreduce.reduce.memory.mb', config['mapreduce.reduce.memory.mb']
        ctx.report 'mapreduce.map.java.opts', config['mapreduce.map.java.opts']
        ctx.report 'mapreduce.reduce.java.opts', config['mapreduce.reduce.java.opts']
        ctx.report 'mapreduce.task.io.sort.mb', config['mapreduce.task.io.sort.mb']
        next null, true

## Module Dependencies

    # mkcmd = require '../lib/mkcmd'
    properties = require '../lib/properties'



