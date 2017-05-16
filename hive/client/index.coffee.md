
# Hive & HCatolog Client
[Hive Client](https://cwiki.apache.org/confluence/display/Hive/HiveClient) is the application that you use in order to administer, use Hive.
Once installed you can type hive in a prompt and the hive client shell wil launch directly.

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
        hadoop_core: 'ryba/hadoop/core/configure'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        yarn_client: 'ryba/hadoop/yarn_client'
        mapred_client: 'ryba/hadoop/mapred_client'
        tez: implicit: true, module: 'ryba/tez'
        hcat: 'ryba/hive/hcatalog'
        ranger_admin: 'ryba/ranger/admin'
      configure:
        'ryba/hive/client/configure'
      commands:
        'install': [
          'ryba/hive/client/install'
          'ryba/hive/client/check'
        ]
        'check':
          'ryba/hive/client/check'
