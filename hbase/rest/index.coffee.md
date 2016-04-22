
# HBase Rest Gateway
Stargate is the name of the REST server bundled with HBase.
The [REST Server](http://wiki.apache.org/hadoop/Hbase/Stargate) is a daemon which enables other application to request HBASE database via http.
Of course we deploy the secured version of the configuration of this API.

    module.exports = ->
      'check':
        'ryba/hbase/rest/check'
      'configure': [
        'masson/core/iptables'
        'ryba/hbase/rest/configure'
      ]
      'install': [
        'masson/core/iptables'
        'ryba/hadoop/hdfs_client'
        'ryba/hbase/client'
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
