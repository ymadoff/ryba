
# Elastic Search 

[Elasticsearch](http://www.elastic.co) is a higly-available, distributed  and scalable search Engine.
Elastic search is based on a restful api and indexes data with http Put requests.
It associated with kibana Logstash in order to visualizes data and transform it.
Hadoop being the place of big data , Elasticsearch integrates perfeclty into it.
Ryba can deploy Elasticsearch in the  secured Hadoop cluster.


Elastic search configuration for hadoop can be found at [Hortonworks Section](hortonworks.com/blog/configure-elastic-search-hadoop-hdp-2-0)

    module.exports =
      use:
        java: implicit: true, module: 'masson/commons/java'
      configure:
        'ryba/elasticsearch/configure'
      commands:
        'prepare':
          'ryba/elasticsearch/prepare'
        'install': [
          'ryba/elasticsearch/install'
          'ryba/elasticsearch/start'
        ]
        'start':
          'ryba/elasticsearch/start'
        'status':
          'ryba/elasticsearch/status'
        'stop':
          'ryba/elasticsearch/stop'
