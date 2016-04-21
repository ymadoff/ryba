
# NiFi Node Agent Start

    module.exports = header: 'NiFi Node Start', label_true: 'STARTED', handler: ->
      @execute
        cmd: 'service nifi-node start'
        if_exists: '/etc/init.d/nifi-node'
        if_exec: 'service nifi-node status| grep \'Apache NiFi is not running\''
