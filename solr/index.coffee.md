
# Solr
[Solr](http://lucene.apache.org/solr/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/)

    module.exports = ->
      'configure': [
        'ryba/solr/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/solr/install'
            
      ]
      'start': [
        'ryba/solr/start'
      ]
      'stop': [
        'ryba/solr/stop'
      ]
      'status': [
        'ryba/solr/status'
      ]
      'prepare': [
        'ryba/solr/prepare'
      ]
