
# Ganglia Monitor Start

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Monitor # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hdp-gmond'
        if_exists: '/etc/init.d/hdp-gmond'
      .then next


