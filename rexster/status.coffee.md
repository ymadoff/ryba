
# Rexster Status

Run the command `./bin/ryba status -m ryba/titan/rexster` to retrieve the status
of the Titan server using Ryba.

    module.exports = header: 'Rexster Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: "ps aux | grep 'com.tinkerpop.rexster.Application'"
        code_skipped: 1
