
# Rexster Status

Run the command `./bin/ryba status -m ryba/titan/rexster` to retrieve the status
of the Titan server using Ryba.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./').configure

## Status

Discover the server status.

    module.exports.push header: 'Rexster # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: "ps aux | grep 'com.tinkerpop.rexster.Application'"
        code_skipped: 1
