
# Solr Cloud

[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)

    module.exports = 
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        docker: implicit: true, module: 'masson/commons/docker'
        hadoop_core: module: 'ryba/hadoop/core'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        zoo_server: module: 'ryba/zookeeper/server'
      configure: 'ryba/solr/cloud/configure'
      commands:
        'prepare': [
          'ryba/solr/cloud/prepare'
        ]
        'install': [
          'ryba/solr/cloud/install'
          'ryba/solr/cloud/start'
          'ryba/solr/cloud/check'
        ]
        'start': [
          'ryba/solr/cloud/start'
        ]
        'stop':  'ryba/solr/cloud/stop'
        'check':  'ryba/solr/cloud/check'
