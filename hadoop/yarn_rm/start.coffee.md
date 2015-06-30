
# Hadoop YARN ResourceManager Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs_dn/wait'
    module.exports.push 'ryba/hadoop/yarn_ts/wait'
    module.exports.push 'ryba/hadoop/mapred_jhs/wait'
    module.exports.push require('./index').configure

## Wait Active

Only apply with manual failaover and to the passive RM which must wait for the
active RM to be started.

    module.exports.push name: 'Yarn RM # Wait Active', label_true: 'STARTED', timeout: -1, handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      return next() if yarn.site['yarn.resourcemanager.ha.automatic-failover.enabled'] is 'true'
      rm_ctxs = ctx.contexts modules: 'ryba/hadoop/yarn_rm', require('./index').configure
      return next() unless rm_ctxs.length > 1 # Skip unless HA
      return next() if yarn.active_rm_host is ctx.config.host # Skip unless passive
      [active_rm_shortname] = rm_ctxs
      .filter (rm_ctx) -> rm_ctx.config.host is yarn.active_rm_host
      .map (rm_ctx) -> rm_ctx.config.shortname
      ctx.waitForExecution
        cmd: "yarn rmadmin -getServiceState '#{active_rm_shortname}'"
        code_skipped: 255
      , next

## Start

Start the ResourceManager server. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-resourcemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
```

    module.exports.push name: 'Yarn RM # Start', label_true: 'STARTED', handler: (ctx, next) ->
      {yarn} = ctx.config.ryba
      ctx
      .remove
        destination: "#{yarn.pid_dir}/yarn-#{yarn.user.name}-resourcemanager.pid"
        if: ctx.retry > 0
      .service_start
        name: 'hadoop-yarn-resourcemanager'
        if_exists: '/etc/init.d/hadoop-yarn-resourcemanager'
      .then next

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
      return next() unless rm_ctxs.length > 1 # Skip unless HA
      return next() unless yarn.active_rm_host is ctx.config.host # Skip unless active_rm_shortname
      active_rm_shortname = passive_rm_shortname = null
      for rm_ctx in rm_ctxs
        active_rm_shortname = rm_ctx.config.shortname if rm_ctx.config.host is yarn.active_rm_host
        passive_rm_shortname = rm_ctx.config.shortname if rm_ctx.config.host isnt yarn.active_rm_host
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if yarn rmadmin -getServiceState '#{active_rm_shortname}' | grep standby; then
          yarn rmadmin -transitionToStandby '#{passive_rm_shortname}';
          yarn rmadmin -transitionToActive '#{active_rm_shortname}';
        else exit 2; fi
        """
        code_skipped: 2
      .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'

## Errors

*   Message "yarn is trying to renew a token with wrong password"  on startup
    Cause: an application fail to recover
    Solution: remove the zookeeper entries `rmr /rmstore`

