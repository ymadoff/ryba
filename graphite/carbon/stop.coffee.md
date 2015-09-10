
# Graphite Carbon Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    # /opt/graphite/bin/carbon-cache.py stop
    module.exports.push name: 'Graphite Carbon # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'carbon-cache'
        action: 'stop'
        if_exists: '/etc/init.d/carbon-cache'
