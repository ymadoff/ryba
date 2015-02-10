
# WebHCat Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./webhcat').configure

## Status

Check if the HCatalog is running. The process ID is located by default
inside "/var/lib/hive-hcatalog/hcat.pid".

    module.exports.push name: 'Hive & HCat Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hive-hcatalog-server status'
        code_skipped: 3
        if_exists: '/etc/init.d/hive-hcatalog-server'
      , next

## Status

Check if the Hive Server2 is running. The process ID is located by default
inside "/var/run/hive/hive-server2.pid".

    module.exports.push name: 'Hive & HCat Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hive-server2 status'
        code_skipped: 3
        if_exists: '/etc/init.d/hive-server2'
      , next

