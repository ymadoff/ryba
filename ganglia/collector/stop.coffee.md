
# Ganglia Monitor Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Collector # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hdp-gmetad'
        if_exists: '/etc/init.d/hdp-gmetad'
