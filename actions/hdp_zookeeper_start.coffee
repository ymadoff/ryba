
hdp = require './hdp'
hdp_zookeeper = require './hdp_zookeeper'
module.exports = []

module.exports.push (ctx) ->
  hdp.configure ctx
  hdp_zookeeper.configure ctx

###
Start ZooKeeper
---------------
Execute these commands on the ZooKeeper host machine(s).
###
module.exports.push (ctx, next) ->
  {zookeeper} = ctx.config.hdp
  {user} = ctx.config.hdp_zookeeper
  return next() unless zookeeper
  @name "HDP # Start ZooKeeper"
  ctx.execute
    # su - zookeeper -c "export ZOOCFGDIR=/etc/zookeeper/conf ; export ZOOCFG=zoo.cfg ; source /etc/zookeeper/conf/zookeeper-env.sh ; /usr/lib/zookeeper/bin/zkServer.sh start"
    cmd: "su - #{user} -c \"export ZOOCFGDIR=/etc/zookeeper/conf ; export ZOOCFG=zoo.cfg ; source /etc/zookeeper/conf/zookeeper-env.sh ; /usr/lib/zookeeper/bin/zkServer.sh start\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

