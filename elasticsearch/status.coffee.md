
# ElasticSearch Status

This commands checks the status of ElasticSearch (STARTED, STOPPED)

    module.exports = header: 'ES Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'elasticsearch'
