
# Elasticsearch Configuration (Standalon Mode)

### Global configuration

*   `cluster.name` (string)
    name of the cluster
    Default: 'elastic'
*   `number_of_shards` (int)
    Default: number of nodelasticsearch
*   `number_of_replicas` (int)
    Default: 1

### Host-specific configuration

Thelasticsearche variablelasticsearch MUST be set in the host configuration level.

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

    module.exports  = ->
      es_ctxs = @contexts 'ryba/elasticsearch'
      elasticsearch = @config.ryba.elasticsearch ?= {}
      elasticsearch.user ?= {}
      elasticsearch.user = name: elasticsearch.user if typeof elasticsearch.user is 'string'
      elasticsearch.user.name ?= 'elasticsearch'
      #elasticsearch.user.home ?= ""
      elasticsearch.user.system ?= true
      elasticsearch.user.comment ?= 'ElasticSearch User'
      # Group
      elasticsearch.group ?= {}
      elasticsearch.group = name: elasticsearch.group if typeof elasticsearch.group is 'string'
      elasticsearch.group.name ?= 'elasticsearch'
      elasticsearch.group.system ?= true
      elasticsearch.user.gid ?= elasticsearch.group.name
      # Layout
      elasticsearch.version ?= '5.0.0'
      # Kerberos
      elasticsearch.principal ?= "elasticsearch/#{@config.host}@#{@config.ryba.realm}"
      elasticsearch.keytab ?= '/etc/security/keytabs/elasticsearch.service.keytab'
      elasticsearch.cluster ?= {}
      elasticsearch.cluster.name ?= 'elasticsearch'
      elasticsearch.number_of_shards ?= es_ctxs.length
      elasticsearch.number_of_replicas ?= 1

ElasticSearch can be found [here](https://www.elastic.co/downloads).

      elasticsearch.source ?= "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-#{elasticsearch.version}.rpm"
