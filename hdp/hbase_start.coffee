
module.exports = []
module.exports.push 'phyla/bootstrap'

# ###
# Start HBase Master
# ------------------
# Execute these commands on the HBase Master host machine.
# ###
# module.exports.push (ctx, next) ->
#   {hbase_master, hbase_user} = ctx.config.hdp
#   @name "HDP # Start HBase Master"
#   return next() unless hbase_master
#   ctx.execute
#     # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master"
#     cmd: "su -l #{hbase_user} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master\""
#   , (err, executed) ->
#     next err, if executed then ctx.OK else ctx.PASS

# ###
# Start HBase Region Server
# -------------------------
# Execute these commands on all RegionServers
# ###
# module.exports.push (ctx, next) ->
#   {hbase_regionserver, hbase_user} = ctx.config.hdp
#   return next() unless hbase_regionserver
#   @name "HDP # Start HBase Region Server"
#   ctx.execute
#     # su -l hbase -c "/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver"
#     cmd: "su -l #{hbase_user} -c \"/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver\""
#   , (err, executed) ->
#     next err, if executed then ctx.OK else ctx.PASS