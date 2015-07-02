
# WebHCat Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Status

Check if the RegionServer is running. The process ID is located by default
inside "/var/run/webhcat/webhcat.pid".

    module.exports.push name: 'WebHCat # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hive-webhcat-server status'
        code_skipped: 3
        if_exists: '/etc/init.d/hive-webhcat-server'
      .then next

