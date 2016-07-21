
# ElasticSearch Prepared

    module.exports = header: 'ES Prepared', handler: ->
      {elasticsearch, realm} = @config.ryba
      @cache
        ssh: null
        source: elasticsearch.source
        # destination: "/var/tmp/elasticsearch-#{elasticsearch.version}.noarch.rpm"

