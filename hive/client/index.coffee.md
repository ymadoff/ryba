
# Hive & HCatolog Client
[Hive Client](https://cwiki.apache.org/confluence/display/Hive/HiveClient) is the application that you use in order to administer, use Hive.
Once installed you can type hive in a prompt and the hive client shell wil launch directly.

    module.exports = ->
      'configure': [
        'ryba/hadoop/core/configure'
        'ryba/tez/configure'
        'ryba/hive/client/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/hadoop/core'
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/yarn_client'
        'ryba/hadoop/mapred_client'
        'ryba/tez'
        'ryba/lib/hconfigure'
        'ryba/hive/client/install'
        'ryba/hive/hcatalog/wait'
        'ryba/hive/server2/wait'
        'ryba/hive/client/check'
      ]
      'check': [    
        'ryba/hive/hcatalog/wait'
        'ryba/hive/server2/wait'
        'ryba/hive/client/check'
    ]
