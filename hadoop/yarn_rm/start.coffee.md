
# Hadoop YARN ResourceManager Start

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_dn_wait'
    module.exports.push require('./index').configure

    module.exports.push name: 'Yarn RM # Start Server', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.rm_start ctx, next

## Ensure Active/Standby

Check the status of the ResourceManagers and ensure the expected active server
is in the right active state. Note, this only apply if automatic failover is
not enabled (enabled by default).

Running `rmadmin -failover` with automatic failover enabled result in an error
with the message "RMHAServiceTarget doesn't have a corresponding ZKFC address".

    module.exports.push name: 'Yarn RM # Ensure Active/Standby', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      return next() if yarn.site['yarn.resourcemanager.ha.automatic-failover.enabled'] is 'true'
      rm_ctxs = ctx.contexts modules: 'ryba/hadoop/yarn_rm', require('./index').configure
      return next() unless rm_ctxs.length > 1
      return next() unless yarn.active_rm_host is ctx.config.host
      active_rm_shortname = passive_rm_shortname = null
      for rm_ctx in rm_ctxs
        active_rm_shortname = rm_ctx.config.shortname if rm_ctx.config.host is yarn.active_rm_host
        passive_rm_shortname = rm_ctx.config.shortname if rm_ctx.config.host isnt yarn.active_rm_host
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if yarn rmadmin -getServiceState #{active_rm_shortname} | grep standby;
        then yarn rmadmin -failover #{passive_rm_shortname} #{active_rm_shortname};
        else exit 2; fi
        """
        code_skipped: 2
      , next

## Module Dependencies

    mkcmd = require '../../lib/mkcmd'

## Errors

*   Message "yarn is trying to renew a token with wrong password"  on startup
    Cause: an application fail to recover
    Solution: remove the zookeeper entries `rmr /rmstore`

