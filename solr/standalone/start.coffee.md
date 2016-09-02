
# Solr Start

    module.exports =  header: 'Solr Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'solr'
