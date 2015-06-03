
# Ganglia Monitor Stop

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Collector # Stop', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'hdp-gmetad'
        action: 'stop'
        if_exists: '/etc/init.d/hdp-gmetad'
      .then next
