
# YARN NodeManager Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Status

Check if the Yarn NodeManager server is running. The process ID is located by
default inside "/var/run/hadoop-yarn/yarn-yarn-nodemanager.pid".

    module.exports.push name: 'YARN NM # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hadoop-yarn-nodemanager status'
        code_skipped: 3
        if_exists: '/etc/init.d/hadoop-yarn-nodemanager'
      .then next
