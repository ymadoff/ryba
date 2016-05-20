
    
    module.exports = ->
      'configure': [
        'ryba/solr/cloud/configure'
      ]
      'prepare': [
        'ryba/solr/cloud/prepare'
      ]
      'install': [
        'ryba/solr/cloud/install'
        'ryba/solr/cloud/start'
        'ryba/solr/cloud/check'
      ]
      'start': [
        'ryba/solr/cloud/start'
      ]
      'stop':  'ryba/solr/cloud/stop'
      'check':  'ryba/solr/cloud/check'
      
