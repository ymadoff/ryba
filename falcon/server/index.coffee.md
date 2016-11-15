
# Falcon Server

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
        hcatalog: 'ryba/hive/hcatalog'
        falcon: 'ryba/falcon/server'
        oozie: 'ryba/oozie/server'
      configure:
        'ryba/falcon/server/configure'  
      commands:
        'install': [
          'ryba/falcon/server/install'
          'ryba/falcon/server/start'
          'ryba/falcon/server/check'
        ]
        'check':
          'ryba/falcon/server/check'
        'start':
          'ryba/falcon/server/start'
        'stop':
          'ryba/falcon/server/stop'
        'status':
          'ryba/falcon/server/status'

[falcon]: http://falcon.incubator.apache.org/
