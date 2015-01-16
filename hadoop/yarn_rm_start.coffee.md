
# Hadoop YARN ResourceManager Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push require('./yarn_rm').configure

    module.exports.push name: 'Yarn RM # Start Server', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.rm_start ctx, next

    module.exports.push name: 'Yarn RM # Ensure Active/Standby', label_true: 'TODO', handler: (ctx, next) ->
      rm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
      return next() unless rm_hosts.length > 1 
      {active_rm_host} = ctx.config.ryba
      # if active_rm_host is ctx.config.host
      #   # todo
      next null, true

## Errors

*   Message "yarn is trying to renew a token with wrong password"  on startup
    Cause: an application fail to recover
    Solution: remove the zookeeper entry `rmr /rmstore`

