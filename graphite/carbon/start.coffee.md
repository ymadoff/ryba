
# Graphite Carbon Start

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    # /opt/graphite/bin/carbon-cache.py start
    module.exports.push name: 'Graphite Carbon # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'carbon-cache'
        if_exists: '/etc/init.d/carbon-cache'
