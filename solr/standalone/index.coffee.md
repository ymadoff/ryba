
# Solr
[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)

    module.exports = ->
      'configure': [
        'ryba/solr/standalone/configure'
      ]
      'install': [
        'masson/commons/java'
        'ryba/solr/standalone/install'
            
      ]
      'start': [
        'ryba/solr/standalone/start'
      ]
      'stop': [
        'ryba/solr/standalone/stop'
      ]
      'status': [
        'ryba/solr/standalone/status'
      ]
      'prepare': [
        'ryba/solr/standalone/prepare'
      ]
