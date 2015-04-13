
# Hadoop ZKFC

The [ZKFailoverController (ZKFC)](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) is a new component which is a ZooKeeper client which also monitors and manages the state of the NameNode.
 Each of the machines which runs a NameNode also runs a ZKFC, and that ZKFC is responsible for Health monitoring, ZooKeeper session management, ZooKeeper-based election.


    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push module.exports.configure = (ctx) ->
      require('../core').configure ctx
      {ryba} = ctx.config
      ryba.hdfs ?= {}
      # Validation
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn',(require '../hdfs_nn').configure
      throw Error "Require 2 NameNodes" unless nn_ctxs.length is 2
      # Environment
      ryba.hdfs.zkfc_opts ?= ''
      if ryba.core_site['hadoop.security.authentication'] is 'kerberos'
        ryba.hdfs.zkfc_opts = "-Djava.security.auth.login.config=#{ryba.hadoop_conf_dir}/hdfs-zkfc.jaas #{ryba.hdfs.zkfc_opts}"
      ryba.hdfs.zkfc_digest ?= {}
      ryba.hdfs.zkfc_digest.name ?= 'hdfs-zkfc'
      ryba.hdfs.zkfc_digest.password ?= null
      # Enrich "core-site.xml" with acl and auth
      ryba.core_site['ha.zookeeper.acl'] ?= "@#{ryba.hadoop_conf_dir}/zk-acl.txt"
      ryba.core_site['ha.zookeeper.auth'] = "@#{ryba.hadoop_conf_dir}/zk-auth.txt"
      # Import NameNode properties
      # Note: need 'ha.zookeeper.quorum', 'dfs.ha.automatic-failover.enabled'
      require('../hdfs_nn').configure ctx

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hadoop/zkfc/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/zkfc/install'
      'ryba/hadoop/zkfc/start'
      'ryba/hadoop/zkfc/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/zkfc/start'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/zkfc/stop'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/zkfc/status'
