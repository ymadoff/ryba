
hdp = require './hdp_core'
module.exports = []

module.exports.push (ctx) ->
  hdp.configure ctx

###
Start Hive Metastore
--------------------
Execute these commands on the Hive Metastore host machine.
###
module.exports.push (ctx, next) ->
  {hive_metastore, hive_user, hive_log_dir} = ctx.config.hdp
  return next() unless hive_metastore
  @name "HDP # Start Hive Metastore"
  ctx.execute
    # su -l hive -c "export HADOOP_HOME=/usr/lib/hadoop && nohup hive --service metastore > /var/log/hive/hive.out 2> /var/log/hive/hive.log &"
    # su -l hive -c "export HADOOP_HOME=/usr/lib/hadoop && hive --service metastore"
    cmd: "su -l #{hive_user} -c \"export HADOOP_HOME=/usr/lib/hadoop && nohup hive --service metastore > #{hive_log_dir}/hive.out 2> #{hive_log_dir}/hive.log &\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

###
Start Server2
-------------
Execute these commands on the Hive Server2 host machine.
###
module.exports.push (ctx, next) ->
  @name "HDP # Start Hive Server2"
  {hive_user, hive_log_dir} = ctx.config.hdp
  ctx.execute
    # su -l hive -c "export HADOOP_HOME=/usr/lib/hadoop && nohup hive --service hiveserver2 -hiveconf hive.metastore.uris=' ' > /var/log/hive/hiveServer2.out 2>/var/log/hive/hiveServer2.log &"
    # su -l hive -c "export HADOOP_HOME=/usr/lib/hadoop && hive --service hiveserver2 -hiveconf hive.metastore.uris=' '"
    cmd: "su -l #{hive_user} -c \"export HADOOP_HOME=/usr/lib/hadoop && nohup /usr/lib/hive/bin/hiveserver2 -hiveconf hive.metastore.uris=' ' > #{hive_log_dir}/hiveServer2.out 2>#{hive_log_dir}/hiveServer2.log &\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

# ###
# Start WebHCat
# -------------
# Execute these commands on the WebHCat host machine
# ###
# module.exports.push (ctx, next) ->
#   @name "HDP # Start WebHCat"
#   {webhcat_user} = ctx.config.hdp
#   ctx.execute
#     cmd: "su -l #{webhcat_user} -c \"/usr/lib/hcatalog/sbin/webhcat_server.sh  start\""
#   , (err, executed) ->
#     next err, if executed then ctx.OK else ctx.PASS