
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push 'histi/actions/nc'
module.exports.push 'histi/hdp/yarn'

module.exports.push (ctx) ->
  require('../actions/nc').configure ctx
  require('./yarn').configure ctx

module.exports.push name: 'HDP YARN NM # Start', callback: (ctx, next) ->
  resourcemanager = ctx.hosts_with_module 'histi/hdp/yarn_rm', 1
  ctx.waitForConnection resourcemanager, 8088, (err) ->
    return next err if err
    lifecycle.nm_start ctx, (err, started) ->
      next err, if started then ctx.OK else ctx.PASS

module.exports.push name: 'HDP YARN NM # Test User', callback: (ctx, next) ->
  {test_user, hadoop_group} = ctx.config.hdp
  ctx.execute
    cmd: "useradd #{test_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop to test\""
    code: 0
    code_skipped: 9
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS