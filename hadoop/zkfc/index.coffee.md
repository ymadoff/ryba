
# Hadoop ZKFC

The [ZKFailoverController (ZKFC)](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) is a new component which is a ZooKeeper client which also monitors and manages the state of the NameNode.
 Each of the machines which runs a NameNode also runs a ZKFC, and that ZKFC is responsible for Health monitoring, ZooKeeper session management, ZooKeeper-based election.


    module.exports = []
    module.exports.push 'masson/bootstrap'

## Configuration

ZKFC doesnt have any required configuration. By default, it uses the SASL
mechanism to connect to zookeeper using kerberos.

Optional, activate digest type access to zookeeper to manage the zkfc znode:

```json
{
  "ryba": {
    "zkfc": {
      "digest": {
        "name": "zkfc",
        "password": "hdfs123"
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      require('../core').configure ctx
      {ryba, host} = ctx.config
      ryba.zkfc ?= {}
      # Validation
      nn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_nn', require('../hdfs_nn').configure
      throw Error "Require 2 NameNodes" unless nn_ctxs.length is 2
      # ryba.zkfc.principal ?= "zkfc/#{host}@#{ryba.realm}"
      # ryba.zkfc.keytab ?= '/etc/security/keytabs/zkfc.service.keytab'
      ryba.zkfc.principal ?= ryba.hdfs.site['dfs.namenode.kerberos.principal']
      ryba.zkfc.keytab ?= ryba.hdfs.site['dfs.namenode.keytab.file']
      ryba.zkfc.jaas_file ?= "#{ryba.hadoop_conf_dir}/zkfc.jaas"
      ryba.zkfc.digest ?= {}
      ryba.zkfc.digest.name ?= 'zkfc'
      ryba.zkfc.digest.password ?= null
      # Environment
      ryba.zkfc.opts ?= ''
      if ryba.core_site['hadoop.security.authentication'] is 'kerberos'
        ryba.zkfc.opts = "-Djava.security.auth.login.config=#{ryba.zkfc.jaas_file} #{ryba.zkfc.opts}"
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
