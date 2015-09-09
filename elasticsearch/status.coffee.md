
# ElasticSearch Status

This commands checks the status of ElasticSearch (STARTED, STOPPED)

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

    module.exports.push name: 'ES # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service elasticsearch status'
        code_skipped: 3
