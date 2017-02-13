
# Elasticsearch Prepared

    module.exports = header: 'ES Prepared', handler: ->
      {elasticsearch, realm} = @config.ryba
      @cache
        ssh: null
        source: elasticsearch.source
        # target: "/var/tmp/elasticsearch-#{elasticsearch.version}.noarch.rpm"
