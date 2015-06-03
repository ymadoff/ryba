
# Ganglia Monitor Start

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Monitor # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service_start
        name: 'hdp-gmond'
        if_exists: '/etc/init.d/hdp-gmond'
      # On error, it is often necessary to remove pid files
      # this hasnt been tested yet:
      # .execute
      #   cmd: "rm -rf /var/run/ganglia/hdp/*/*.pid"
      #   if: @retry
      .then next


