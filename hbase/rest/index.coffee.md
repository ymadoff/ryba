
# HBase Rest Gateway
Stargate is the name of the REST server bundled with HBase.
The [REST Server](http://wiki.apache.org/hadoop/Hbase/Stargate) is a daemon which enables other application to request HBASE database via http.
Of course we deploy the secured version of the configuration of this API.

    module.exports = ->
      'configure': [
        'masson/core/iptables'
        'ryba/hbase/rest/configure'
      ]
      'install': [
        'masson/core/iptables'
        'ryba/lib/hconfigure'
        'ryba/lib/hdp_select'
        'ryba/lib/write_jaas'
        'ryba/hadoop/hdfs_client'
        'ryba/hbase/common'
        'ryba/hbase/rest/install'
        'ryba/hbase/rest/start'
        'ryba/hbase/rest/check'
      ]
      'start':[
        'masson/core/krb5_client/wait'
        'ryba/zookeeper/server/wait'
        'ryba/hadoop/hdfs_nn/wait'
        'ryba/hbase/master/wait'
        'ryba/hbase/rest/start'
      ]
      'status':
        'ryba/hbase/rest/status'
      'stop':
        'ryba/hbase/rest/stop'
      'check': [
        'ryba/hbase/regionserver/wait'
        'ryba/hbase/rest/check'
      ]
