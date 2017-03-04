
# Graphite Carbon Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/nikita'

    # /opt/graphite/bin/carbon-cache.py stop
    module.exports.push header: 'Graphite Carbon Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        header: 'Start service'
        name: 'carbon-cache'
        if_exists: '/etc/init.d/carbon-cache'
