
# Solr cloud_docker on docker

[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)
This module enables adminstrator to manage severale solrcloud_docker instances running in docker containers.
For now it writes docker-compose.yml file, download resource files, create layout direcoties
but does not start the clusters.

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
