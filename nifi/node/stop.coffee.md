# NiFi Master Stop

    module.exports = header: 'NiFi Node Stop', label_true: 'STOPPED', handler: ->
      @execute
        cmd: 'service nifi-node stop'
        unless_exec: 'service nifi-node status| grep \'Apache NiFi is not running\''
