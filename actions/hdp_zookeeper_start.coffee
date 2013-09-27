
hdp = require './hdp'
module.exports = []

module.exports.push (ctx) ->
  hdp.configure ctx

###
Start ZooKeeper
---------------
Execute these commands on the ZooKeeper host machine(s).
###
module.exports.push (ctx, next) ->
  {zookeeper, zookeeper_user} = ctx.config.hdp
  return next() unless zookeeper
  @name "HDP # Start ZooKeeper"
  ctx.execute
    # su - zookeeper -c "export ZOOCFGDIR=/etc/zookeeper/conf ; export ZOOCFG=zoo.cfg ; source /etc/zookeeper/conf/zookeeper-env.sh ; /usr/lib/zookeeper/bin/zkServer.sh start"
    cmd: "su - #{zookeeper_user} -c \"export ZOOCFGDIR=/etc/zookeeper/conf ; export ZOOCFG=zoo.cfg ; source /etc/zookeeper/conf/zookeeper-env.sh ; /usr/lib/zookeeper/bin/zkServer.sh start\""
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

