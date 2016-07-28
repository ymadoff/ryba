
# Solr cloud_docker on docker

[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)
This module enables adminstrator to manage severale solrcloud_docker instances running in docker containers.


    module.exports = ->
      'configure': [
        'ryba/solr/cloud_docker/configure'
      ]
      'prepare': [
        'ryba/solr/cloud_docker/prepare'
      ]
      'install': [
        'masson/commons/docker'
        'ryba/hadoop/core/install'
        'ryba/solr/cloud_docker/install'
        ]
      #   'ryba/solr/cloud_docker/start'
      #   'ryba/solr/cloud_docker/check'
      # ]
      # 'start': [
      #   'ryba/solr/cloud_docker/start'
      # ]
      # 'stop':  'ryba/solr/cloud_docker/stop'
      # 'check':  'ryba/solr/cloud_docker/check'
      
