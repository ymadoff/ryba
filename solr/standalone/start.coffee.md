
# Solr Start

    module.exports =  header: 'Solr Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'solr'
