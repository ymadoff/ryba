
# Cloudera Manager Agent Status

This commands checks the status of Cloudera Manager Agent (STARTED, STOPPED)

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

    module.exports.push header: 'Cloudera Manager Agent # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service cloudera-scm-agent status'
        code_skipped: 3
