
# Elastic Search 

[Elasticsearch](http://www.elastic.co) is a higly-available, distributed  and scalable search Engine.
Elastic search is based on a restful api and indexes data with http Put requests.
It associated with kibana Logstash in order to visualizes data and transform it.
Hadoop being the place of big data , Elasticsearch integrates perfeclty into it.
Ryba can deploy Elasticsearch in the  secured Hadoop cluster.


Elastic search configuration for hadoop can be found at [Hortonworks Section](hortonworks.com/blog/configure-elastic-search-hadoop-hdp-2-0)

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Configure

### Global configuration

*   `cluster.name` (string)
    name of the cluster
    Default: 'elastic'
*   `number_of_shards` (int)
    Default: number of nodes
*   `number_of_replicas` (int)
    Default: 1

### Host-specific configuration

These variables MUST be set in the host configuration level.

*   `node.name` (string)
    name of the node WARNING: MUST BE UNIQUE for each node !
    Default: random value.
*   `node.master` (boolean)
    Is leader
*   `node.data` (boolean)
    Is follower

Example:

```json
{
  "ryba": {
    "elasticsearch": {
      "cluster":{
        name": "elastic"
      },
      "number_of_shards": 5,
      "number_of_replicas": 1
    }
  },
  "master3.ryba":{
    "config": {
      "ryba": {
        "elasticsearch": {
          "node": {
            "name": "node3",
            "master": true,
            "data": false
          }
        }
      }
    }
  }
}
```

    module.exports.configure = (ctx) ->
      es = ctx.config.ryba.elasticsearch ?= {}
      es.user ?= {}
      es.user = name: es.user if typeof es.user is 'string'
      es.user.name ?= 'elasticsearch'
      #es.user.home ?= ""
      es.user.system ?= true
      es.user.comment ?= 'ElasticSearch User'
      # Group
      es.group ?= {}
      es.group = name: es.group if typeof es.group is 'string'
      es.group.name ?= 'elasticsearch'
      es.group.system ?= true
      es.user.gid ?= es.group.name
      # Layout
      es.version ?= '1.2.4'
      es.cluster ?= {}
      es.cluster.name ?= 'elasticsearch'
      es.number_of_shards ?= ctx.hosts_with_module('ryba/elasticsearch').length
      es.number_of_replicas ?= 1

ElasticSearch can be found [here](https://www.elastic.co/downloads/elasticsearch)

      es.source ?= "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{es.version}.noarch.rpm"

    module.exports.push commands: 'install', modules: [
      'ryba/elasticsearch/install',
      'ryba/elasticsearch/start'
    ]

    module.exports.push commands: 'start', modules: 'ryba/elasticsearch/start'

    module.exports.push commands: 'check', modules: 'ryba/elasticsearch/check'

    module.exports.push commands: 'status', modules: 'ryba/elasticsearch/status'

    module.exports.push commands: 'stop', modules: 'ryba/elasticsearch/stop'

## Module Dependencies

    path = require 'path'
