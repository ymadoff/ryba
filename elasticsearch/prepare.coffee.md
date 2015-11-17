
# ElasticSearch Prepared

    module.exports = []
    module.exports.push 'masson/bootstrap'
    
    module.exports.push header: 'ES Prepared', handler: ->
      {elasticsearch, realm} = @config.ryba
      @cache
        ssh: null
        source: elasticsearch.source
        # destination: "/var/tmp/elasticsearch-#{elasticsearch.version}.noarch.rpm"
      
