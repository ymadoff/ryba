
hdp = require './hdp'
module.exports = []

module.exports.push module.exports.configure = (ctx) ->
  ctx.config.hdp_zookeeper ?= {}
  ctx.config.hdp_zookeeper.user ?= 'zookeeper'
  ctx.config.hdp_zookeeper.data_dir ?= '/var/zookeper/data/'
  ctx.config.hdp_zookeeper.conf_dir ?= '/etc/zookeeper/conf'
  ctx.config.hdp_zookeeper.log_dir ?= '/var/log/zookeeper'
  ctx.config.hdp_zookeeper.pid_dir ?= '/var/run/zookeeper'
  hdp.configure ctx

###
Install
-------
Instructions to [install the ZooKeeper RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap9-1.html)
###
module.exports.push (ctx, next) ->
  @name 'HDP ZooKeeper # Install'
  @timeout -1
  ctx.service name: 'zookeeper', (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hadoop_group} = ctx.config.hdp
  {user} = ctx.config.hdp_zookeeper
  @name 'HDP ZooKeeper # Users & Groups'
  ctx.execute
    cmd: "useradd #{user} -c \"ZooKeeper\" -r -g #{hadoop_group} -d /var/run/#{user}"
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  {hadoop_group} = ctx.config.hdp
  {user, data_dir, pid_dir, log_dir} = ctx.config.hdp_zookeeper
  @name 'HDP ZooKeeper # Layout'
  ctx.mkdir [
    destination: data_dir
    uid: user
    gid: hadoop_group
    mode: '755'
  ,
    destination: pid_dir
    uid: user
    gid: hadoop_group
    mode: '755'
  ,
    destination: log_dir
    uid: user
    gid: hadoop_group
    mode: '755'
  ], (err, modified) ->
    next err, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'HDP ZooKeeper # Configure'
  modified = false
  hosts = (ctx.config.servers.filter (s) -> s.hdp?.zookeeper).map (s) -> s.host
  {java_home, hadoop_group} = ctx.config.hdp
  {user, data_dir, pid_dir, log_dir} = ctx.config.hdp_zookeeper
  do_zoo_cfg = ->
    # hosts = for host, i in hosts
    #   "server.#{i+1}=#{host}:2888:3888"
    # hosts = hosts.join '\n'
    mapping = (for host, i in hosts
      "server.#{i+1}=#{host}:2888:3888").join '\n'
    ctx.write
      content: """
      #The number of milliseconds of each tick 
      tickTime=2000 
      #The number of ticks that the initial synchronization phase can take 
      initLimit=10 
      #The number of ticks that can pass between sending a request and getting an acknowledgement
      syncLimit=5 
      #The directory where the snapshot is stored.
      dataDir=#{data_dir}
      #The port at which the clients will connect
      clientPort=2182
      #{mapping}
      """
      destination: '/etc/zookeeper/conf/zoo.cfg'
    , (err, written) ->
      return next err if err
      modified = true if written
      do_myid()
  do_myid = ->
    for host, i in hosts
      id = i+1 if host is ctx.config.host
    ctx.write
      content: id
      destination: "#{data_dir}/myid"
      uid: user
      gid: hadoop_group
    , (err, written) ->
      return next err if err
      modified = true if written
      do_env()
  do_env = ->
    ctx.write
      content: """
      export JAVA_HOME=#{java_home}
      export ZOO_LOG_DIR=#{log_dir}
      export ZOOPIDFILE=#{pid_dir}/zookeeper_server.pid
      export SERVER_JVMFLAGS= 
      """
      destination: '/etc/zookeeper/conf/zookeeper-env.sh'
    , (err, written) ->
      return next err if err
      modified = true if written
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_zoo_cfg()







