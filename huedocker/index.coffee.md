
# Hue (Dockerized)

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
Starting from 3.7 Hue version
configuring hue following HDP [instructions][hdp-2.3.2.0-hue]

This module should be installed after having executed the prepare script.
It will build and copy to /ryba/huedocker/resources the hue_docker.tar docker image to
beloaded to the target server
```
./bin/prepare
```


    module.exports = -> 
      'configure': [
        'ryba/hadoop/core'
        'ryba/commons/db_admin'
        'ryba/huedocker/configure'
      ]
      'install': [
        'ryba/commons/db_admin'
        'masson/core/iptables'
        'masson/commons/java'
        'masson/commons/mysql/client' # Install the mysql connector    
        'masson/core/krb5_client' # kerberos clients to create/test new Hive principal
        'masson/commons/docker'
        'ryba/oozie/client'
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/yarn_client'
        'ryba/hadoop/mapred_client'
        'ryba/hbase/client'
        'ryba/hive/client' # Hue reference hive conf dir
        'ryba/pig/install'
        'ryba/huedocker/install'
        'ryba/huedocker/start'
        'ryba/huedocker/check'
      ]
      'start':
        'ryba/huedocker/start'
      'check':
        'ryba/huedocker/check'
      'wait':
        'ryba/huedocker/wait'
      'stop':
        'ryba/huedocker/stop'
      'status':
        'ryba/huedocker/status'
      'prepare':
        'ryba/huedocker/prepare'


[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)
