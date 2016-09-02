
# Hue Status

Check if the Hue server is running. The process ID is located by default
inside "/var/run/hue/supervisor.pid".

    module.exports = header: 'Hue # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hue'
        if_exists: '/etc/init.d/hue'
