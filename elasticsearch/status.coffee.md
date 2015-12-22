
# ElasticSearch Status

This commands checks the status of ElasticSearch (STARTED, STOPPED)

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

    module.exports.push header: 'ES # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'elasticsearch'
