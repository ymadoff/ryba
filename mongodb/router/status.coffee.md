
# MongoDB Routing Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

    module.exports.push header: 'MongoDB Routing Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service mongos status'
        code_skipped: 3
