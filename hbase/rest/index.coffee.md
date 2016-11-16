
# HBase Rest Gateway
Stargate is the name of the REST server bundled with HBase.
The [REST Server](http://wiki.apache.org/hadoop/Hbase/Stargate) is a daemon which enables other application to request HBASE database via http.
Of course we deploy the secured version of the configuration of this API.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: 'ryba/hadoop/core'
        # hdfs_client: 'ryba/hadoop/hdfs_client'
        hbase_master: 'ryba/hbase/master'
        hbase_regionserver: 'ryba/hbase/regionserver'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure:
        'ryba/hbase/rest/configure'
      commands:
        'check':
          'ryba/hbase/rest/check'
        'install': [
          'ryba/hbase/rest/install'
          'ryba/hbase/rest/start'
          'ryba/hbase/rest/check'
        ]
        'start':
          'ryba/hbase/rest/start'
        'status':
          'ryba/hbase/rest/status'
        'stop':
          'ryba/hbase/rest/stop'
