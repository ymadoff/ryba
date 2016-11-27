
# Hadoop Core

## Encryption

Setting hadoop.rpc.protection to privacy encrypts all communication from clients
to Namenode, from clients to Resource Manager, from datanodes to Namenodes, from
Node Managers to Resource managers, and so on.

Setting dfs.data.transfer.protection to privacy encrypts all data transfer
between clients and Datanodes. The clients could be any HDFS client like a
map-task reading data, reduce-task writing data or a client JVM reading/writing
data.

Setting dfs.http.policy and yarn.http.policy to HTTPS_ONLY causes all HTTP
traffic to be encrypted. This includes the web UI for Namenodes and Resource
Managers, Web HDFS interactions, and others.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        # hdp_repo: 'ryba/commons/repos'
        hdp: 'ryba/hdp'
        ganglia: 'ryba/ganglia'
        graphite: 'ryba/graphite'
      configure:
        'ryba/hadoop/core/configure'
      commands:
        'install': [
          'ryba/hadoop/core/install'
        ]
