
# Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
a Zookeeper Browser and a SDK.

Link to configure [hive hue configuration][hive-hue-ssl] over ssl.

    module.exports = ->
      'backup': [
        'ryba/hue/backup'
      ]
      'configure': [
        'ryba/hadoop/hdfs_client'
        'ryba/hadoop/yarn_client'
        'ryba/hive/client'
        'ryba/hue/configure'
      ]
      'install': [
        'masson/core/iptables'
        'masson/commons/mysql_client' # Install the mysql connector
        'masson/core/krb5_client' # Install kerberos clients to create/test new Hive principal
        'ryba/hadoop/hdfs_client/install' #Set java_home in "hadoop-env.sh"
        'ryba/hadoop/yarn_client/install'
        'ryba/hadoop/mapred_client/install'
        'ryba/hive/client/install' # Hue reference hive conf dir
        'ryba/pig/install'
        'ryba/hue/configure'
        'ryba/hue/install'
        'ryba/hue/start'
      ]
      'start': [
        'ryba/hue/start'
      ]
      'status': [
        'ryba/hue/status'
      ]
      'stop': [
        'ryba/hue/stop'
      ]

[home]: http://gethue.com
[hive-hue-ssl]:(http://www.cloudera.com/content/www/en-us/documentation/cdh/5-0-x/CDH5-Security-Guide/cdh5sg_hue_security.html)
