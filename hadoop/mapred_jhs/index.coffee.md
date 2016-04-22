
# MapReduce JobHistoryServer(JHS)

The mapreduce job history server helps you to keep track about every job launched in the cluster.
Tje job history server gather information for all jobs launched on every distinct server and can be found ( once you kerbos ticket initiated) [here](http://master1.ryba:19888/jobhistory) for example
replace master2.ryba by the address of the server where the server is installed, or by its alias.
Now the jobHistory Server tends to be replace by the Yarn timeline server.


    module.exports = ->
      # 'backup':
      #   'ryba/hadoop/mapred_jhs/backup'
      'check':
        'ryba/hadoop/mapred_jhs/check'
      'configure':
        'ryba/hadoop/mapred_jhs/configure'
      'install': [
        'masson/core/iptables'
        'ryba/hadoop/hdfs_client/install'
        'ryba/hadoop/mapred_jhs/install'
        'ryba/hadoop/mapred_jhs/start'
        'ryba/hadoop/mapred_jhs/check'
      ]
      'start':
        'ryba/hadoop/mapred_jhs/start'
      'status':
        'ryba/hadoop/mapred_jhs/status'
      'stop':
        'ryba/hadoop/mapred_jhs/stop'

[druid]: http://druid.io/docs/latest/configuration/hadoop.html
[amb-mr-site]: https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/stacks/HDP/2.3/services/YARN/configuration-mapred/mapred-site.xml
