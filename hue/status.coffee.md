
# Hue Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the Hue server is running. The process ID is located by default
inside "/var/run/hue/supervisor.pid".

    module.exports.push header: 'Hue # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service hue status'
        code_skipped: 3
        if_exists: '/etc/init.d/hue'
