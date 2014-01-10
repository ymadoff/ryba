
lifecycle = require './hdp/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./hdp_core').configure ctx
  require('./hdp_hive_server').configure ctx

###
Start Hive Metastore
--------------------
Execute these commands on the Hive Metastore host machine.
###
module.exports.push (ctx, next) ->
  {hive_user, hive_log_dir} = ctx.config.hdp
  @name "HDP # Start Hive Metastore"
  lifecycle.hive_metastore_start ctx, (err, started) ->
    next err, ctx.OK

###
Start Server2
-------------
Execute these commands on the Hive Server2 host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Hive Server2"
  {hive_user, hive_log_dir} = ctx.config.hdp
  lifecycle.hive_server2_start ctx, (err, started) ->
    next err, ctx.OK

