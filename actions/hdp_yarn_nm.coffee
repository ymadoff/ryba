
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push 'histi/actions/hdp_yarn'

module.exports.push (ctx) ->
  require('./hdp_yarn').configure ctx

module.exports.push (ctx, next) ->
  @name 'HDP Hadoop NM # Start'
  lifecycle.nm_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {test_user, hadoop_group} = ctx.config.hdp
  @name 'HDP Hadoop NM # Test User'
  ctx.execute
    cmd: "useradd #{test_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop to test\""
    code: 0
    code_skipped: 9
  , (err, created) ->
    next err, if created then ctx.OK else ctx.SKIPPED