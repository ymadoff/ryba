
# Hadoop ZKFC Configure

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

    module.exports = ->
      zkfc_ctxs = @contexts 'ryba/hadoop/zkfc'
      zk_ctxs = @contexts('ryba/zookeeper/server').filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant' )
      throw Error "Require 2 ZKFCs" unless zkfc_ctxs.length is 2
      {ryba, host} = @config
      ryba.zkfc ?= {}
      ryba.zkfc.conf_dir ?= '/etc/hadoop-hdfs-zkfc/conf'
      ryba.zkfc.core_site ?= {}
      ryba.zkfc.core_site['ha.zookeeper.quorum'] ?= zk_ctxs.map( (ctx)-> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}" ).join(',')
      # Validation
      ryba.zkfc.principal ?= ryba.hdfs.nn.site['dfs.namenode.kerberos.principal']
      ryba.zkfc.keytab ?= ryba.hdfs.nn.site['dfs.namenode.keytab.file']
      ryba.zkfc.jaas_file ?= "#{ryba.zkfc.conf_dir}/zkfc.jaas"
      ryba.zkfc.digest ?= {}
      ryba.zkfc.digest.name ?= 'zkfc'
      ryba.zkfc.digest.password ?= null
      # Environment
      ryba.zkfc.opts ?= ''
      if ryba.core_site['hadoop.security.authentication'] is 'kerberos'
        ryba.zkfc.opts = "-Djava.security.auth.login.config=#{ryba.zkfc.jaas_file} #{ryba.zkfc.opts}"
      # Enrich "core-site.xml" with acl and auth
      ryba.core_site['ha.zookeeper.acl'] ?= "@#{ryba.zkfc.conf_dir}/zk-acl.txt"
      ryba.core_site['ha.zookeeper.auth'] = "@#{ryba.zkfc.conf_dir}/zk-auth.txt"
      # ryba.hdfs.nn.site['hdfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      ryba.hdfs.nn.site['dfs.ha.zkfc.port'] ?= '8019'
      # Import NameNode properties
      # Note: need 'ha.zookeeper.quorum', 'dfs.ha.automatic-failover.enabled'
