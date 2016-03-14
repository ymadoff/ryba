
# ElasticSearch Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'ES # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'elasticsearch'
