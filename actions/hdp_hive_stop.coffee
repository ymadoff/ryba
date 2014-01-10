
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hive_server').configure ctx

###
Stop Server2
-------------
Execute these commands on the Hive Server2 host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Stop Hive Server2"
  {hive_user, hive_log_dir} = ctx.config.hdp
  lifecycle.hive_server2_stop ctx, (err, stoped) ->
    next err, ctx.OK

###
Stop Hive Metastore
--------------------
Execute these commands on the Hive Metastore host machine.
###
module.exports.push (ctx, next) ->
  {hive_user, hive_log_dir} = ctx.config.hdp
  @name "HDP # Stop Hive Metastore"
  lifecycle.hive_metastore_stop ctx, (err, stoped) ->
    next err, ctx.OK

