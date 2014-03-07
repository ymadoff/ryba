
lifecycle = require './lib/lifecycle'

module.exports = []
module.exports.push 'phyla/core/yum'
module.exports.push 'phyla/tools/java'
module.exports.push 'phyla/hdp/core'

module.exports.push module.exports.configure = (ctx) ->
  require('./core').configure ctx
  require('../tools/java').configure ctx
  require('../core/nc').configure ctx
  ctx.config.hdp.zookeeper_myid ?= null
  ctx.config.hdp.zookeeper_user ?= 'zookeeper'
  ctx.config.hdp.zookeeper_data_dir ?= '/var/zookeper/data/'
  ctx.config.hdp.zookeeper_conf_dir ?= '/etc/zookeeper/conf'
  ctx.config.hdp.zookeeper_log_dir ?= '/var/log/zookeeper'
  ctx.config.hdp.zookeeper_pid_dir ?= '/var/run/zookeeper'
  ctx.config.hdp.zookeeper_port ?= 2181

###
Install
-------
Instructions to [install the ZooKeeper RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap9-1.html)
###
module.exports.push name: 'HDP ZooKeeper # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service name: 'zookeeper', (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP ZooKeeper # Users & Groups', callback: (ctx, next) ->
  {hadoop_group, zookeeper_user} = ctx.config.hdp
  ctx.execute
    cmd: "useradd #{zookeeper_user} -r -g #{hadoop_group} -d /var/run/#{zookeeper_user} -s /bin/bash -c \"ZooKeeper\""
    code: 0
    code_skipped: 9
  , (err, executed) ->
    next err, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP ZooKeeper # Layout', callback: (ctx, next) ->
  { hadoop_group, zookeeper_user, 
    zookeeper_data_dir, zookeeper_pid_dir, zookeeper_log_dir
  } = ctx.config.hdp
  ctx.mkdir [
    destination: zookeeper_data_dir
    uid: zookeeper_user
    gid: hadoop_group
    mode: '755'
  ,
    destination: zookeeper_pid_dir
    uid: zookeeper_user
    gid: hadoop_group
    mode: '755'
  ,
    destination: zookeeper_log_dir
    uid: zookeeper_user
    gid: hadoop_group
    mode: '755'
  ], (err, modified) ->
    next err, if modified then ctx.OK else ctx.PASS

module.exports.push name: 'HDP ZooKeeper # Configure', callback: (ctx, next) ->
  modified = false
  hosts = ctx.hosts_with_module 'phyla/hdp/zookeeper'
  {java_home} = ctx.config.java
  { hadoop_group,
    zookeeper_user, zookeeper_data_dir, zookeeper_pid_dir, zookeeper_log_dir,
    zookeeper_myid, zookeeper_port
  } = ctx.config.hdp
  do_zoo_cfg = ->
    # hosts = for host, i in hosts
    #   "server.#{i+1}=#{host}:2888:3888"
    # hosts = hosts.join '\n'
    ctx.log 'Prepare zoo.cfg mapping'
    mapping = (for host, i in hosts
      "server.#{i+1}=#{host}:2888:3888").join '\n'
    ctx.log 'Write zoo.cfg'
    ctx.write
      content: """
      # The number of milliseconds of each tick
      tickTime=2000
      # The number of ticks that the initial
      # synchronization phase can take
      initLimit=10
      # The number of ticks that can pass between
      # sending a request and getting an acknowledgement
      syncLimit=5
      # the directory where the snapshot is stored.
      dataDir=#{zookeeper_data_dir}
      # the port at which the clients will connect
      clientPort=#{zookeeper_port}
      #{mapping}
      """
      destination: '/etc/zookeeper/conf/zoo.cfg'
    , (err, written) ->
      return next err if err
      modified = true if written
      do_myid()
  do_myid = ->
    unless zookeeper_myid
      for host, i in hosts
        zookeeper_myid = i+1 if host is ctx.config.host
    ctx.log 'Write myid'
    ctx.write
      content: zookeeper_myid
      destination: "#{zookeeper_data_dir}/myid"
      uid: zookeeper_user
      gid: hadoop_group
    , (err, written) ->
      return next err if err
      modified = true if written
      do_env()
  do_env = ->
    ctx.log 'Write zookeeper-env.sh'
    ctx.write
      content: """
      export JAVA_HOME=#{java_home}
      export ZOO_LOG_DIR=#{zookeeper_log_dir}
      export ZOOPIDFILE=#{zookeeper_pid_dir}/zookeeper_server.pid
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

module.exports.push name: 'HDP ZooKeeper # Kerberos', callback: (ctx, next) ->
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc
    principal: "zookeeper/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "/etc/security/keytabs/zookeeper.service.keytab"
    uid: 'zookeeper'
    gid: 'hadoop'
    #not_if_exists: "/etc/security/keytabs/zookeeper.service.keytab"
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push name: 'HDP ZooKeeper # Start', timeout: -1, callback: (ctx, next) ->
  lifecycle.zookeeper_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

###
todo: [Securing access to ZooKeeper](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithNFS.html)
###





