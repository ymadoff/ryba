
# HDFS ResourceManager Check

Check the health of the ResourceManager(s).

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm_wait'

## Check Health

Connect to the provided ResourceManager to check its health. This command
`yarn rmadmin -checkHealth {serviceId}` return 0 if the ResourceManager is
healthy, non-zero otherwise.

    module.exports.push name: 'Hadoop HDFS NN # Check HA Health', label_true: 'CHECKED', callback: (ctx, next) ->
      return next() unless ctx.hosts_with_module('ryba/hadoop/yarn_rm').length > 1
      ctx.execute
        cmd: mkcmd.hdfs ctx, "yarn rmadmin -checkHealth #{ctx.config.shortname}"
      , next

# Dependencies

    mkcmd = require '../lib/mkcmd'

    
